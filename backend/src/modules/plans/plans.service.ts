import { eq, and, asc, notInArray, inArray } from 'drizzle-orm';
import { db } from '../../db/connection';
import { dailyPlans, planItems, categories, users, timeEntries } from '../../db/schema';
import { CreatePlanInput, UpdatePlanInput } from './plans.validation';
import {
  calculateWakingSeconds,
  calculatePlannedSecondsChange,
  calculateActualSeconds,
  calculateMinimumPlannedSeconds,
  formatDurationFriendly,
} from '../../utils/time-calculations';

export interface PlanItemWithCategory {
  id: string;
  dailyPlanId: string;
  categoryId: string;
  categoryName: string;
  categoryDescription: string;
  categoryColor: string;
  categoryIcon: string;
  plannedSeconds: number;
  remainingSeconds: number;
  startedAt: Date | null;
}

export interface PlanDetails {
  id: string;
  userId: string;
  planDate: string;
  wakingSeconds: number;
  createdAt: Date | null;
  items: PlanItemWithCategory[];
  isExisting?: boolean;
}

export interface CategorySummary {
  categoryId: string;
  categoryName: string;
  categoryDescription: string;
  categoryColor: string;
  categoryIcon: string;
  plannedSeconds: number;
  actualSeconds: number;
  remainingSeconds: number;
  overtimeSeconds: number;
  isRunning: boolean;
  startedAt: Date | null;
}

export interface PlanSummary {
  planId: string | null;
  planDate: string;
  wakingSeconds: number;
  totalPlannedSeconds: number;
  totalActualSeconds: number;
  categories: CategorySummary[];
}

export class PlansService {
  public static async getItemsForPlan(
    planId: string,
  ): Promise<PlanItemWithCategory[]> {
    return db
      .select({
        id: planItems.id,
        dailyPlanId: planItems.dailyPlanId,
        categoryId: planItems.categoryId,
        categoryName: categories.name,
        categoryDescription: categories.description,
        categoryColor: categories.color,
        categoryIcon: categories.icon,
        plannedSeconds: planItems.plannedSeconds,
        remainingSeconds: planItems.remainingSeconds,
        startedAt: planItems.startedAt,
      })
      .from(planItems)
      .innerJoin(categories, eq(planItems.categoryId, categories.id))
      .where(eq(planItems.dailyPlanId, planId))
      .orderBy(asc(categories.sortOrder));
  }

  static async createPlan(
    userId: string,
    data: CreatePlanInput,
  ): Promise<PlanDetails> {
    // 1. Compute waking_seconds server-side from user profile
    const [user] = await db
      .select({
        wakeTime: users.wakeTime,
        bedtime: users.bedtime,
        routineMinutes: users.routineMinutes,
      })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      const err = new Error('User not found');
      (err as any).statusCode = 404;
      throw err;
    }

    const wakingSeconds = calculateWakingSeconds(
      user.wakeTime,
      user.bedtime,
      user.routineMinutes,
    );

    // 2. Validate total planned time <= waking_seconds
    const totalPlanned = data.items.reduce(
      (sum, item) => sum + item.plannedSeconds,
      0,
    );

    if (totalPlanned > wakingSeconds) {
      const err = new Error(
        `Total planned time (${totalPlanned}s) cannot exceed available waking time (${wakingSeconds}s)`,
      );
      (err as any).statusCode = 400;
      throw err;
    }

    // 3. Rule 3: Check if plan already exists for this date.
    // If it already exists, return the existing plan (idempotent creation).
    const [existing] = await db
      .select({ id: dailyPlans.id })
      .from(dailyPlans)
      .where(
        and(
          eq(dailyPlans.userId, userId),
          eq(dailyPlans.planDate, data.planDate),
        ),
      )
      .limit(1);

    if (existing) {
      const existingPlan = await this.getPlanById(userId, existing.id);
      return {
        ...existingPlan,
        isExisting: true,
      };
    }

    // 4. Insert new daily plan
    const [plan] = await db
      .insert(dailyPlans)
      .values({
        userId,
        planDate: data.planDate,
        wakingSeconds,
      })
      .returning();

    // 5. Insert plan items
    if (data.items.length > 0) {
      await db.insert(planItems).values(
        data.items.map((item) => ({
          dailyPlanId: plan.id,
          userId,
          categoryId: item.categoryId,
          plannedSeconds: item.plannedSeconds,
          remainingSeconds: item.plannedSeconds,
        })),
      );
    }

    const items = await this.getItemsForPlan(plan.id);
    return {
      id: plan.id,
      userId: plan.userId,
      planDate: plan.planDate,
      wakingSeconds: plan.wakingSeconds,
      createdAt: plan.createdAt,
      items,
      isExisting: false,
    };
  }

  static async getPlanByDate(
    userId: string,
    planDate: string,
  ): Promise<PlanDetails | null> {
    const [plan] = await db
      .select()
      .from(dailyPlans)
      .where(
        and(eq(dailyPlans.userId, userId), eq(dailyPlans.planDate, planDate)),
      )
      .limit(1);

    if (!plan) return null;

    const items = await this.getItemsForPlan(plan.id);
    return {
      id: plan.id,
      userId: plan.userId,
      planDate: plan.planDate,
      wakingSeconds: plan.wakingSeconds,
      createdAt: plan.createdAt,
      items,
    };
  }

  static async getPlanById(
    userId: string,
    planId: string,
  ): Promise<PlanDetails> {
    const [plan] = await db
      .select()
      .from(dailyPlans)
      .where(and(eq(dailyPlans.id, planId), eq(dailyPlans.userId, userId)))
      .limit(1);

    if (!plan) {
      const err = new Error('Daily plan not found');
      (err as any).statusCode = 404;
      throw err;
    }

    const items = await this.getItemsForPlan(plan.id);
    return {
      id: plan.id,
      userId: plan.userId,
      planDate: plan.planDate,
      wakingSeconds: plan.wakingSeconds,
      createdAt: plan.createdAt,
      items,
    };
  }

  static async updatePlan(
    userId: string,
    planId: string,
    data: UpdatePlanInput,
  ): Promise<PlanDetails> {
    const [existingPlan] = await db
      .select()
      .from(dailyPlans)
      .where(and(eq(dailyPlans.id, planId), eq(dailyPlans.userId, userId)))
      .limit(1);

    if (!existingPlan) {
      const err = new Error('Daily plan not found');
      (err as any).statusCode = 404;
      throw err;
    }

    // Rule 10: Cannot modify a plan from a past day
    const todayStr = new Date().toISOString().split('T')[0];
    if (existingPlan.planDate < todayStr) {
      const err = new Error('Cannot modify a plan from a past date');
      (err as any).statusCode = 400;
      throw err;
    }

    const wakingSeconds = existingPlan.wakingSeconds;

    if (data.items) {
      const totalPlanned = data.items.reduce(
        (sum, item) => sum + item.plannedSeconds,
        0,
      );
      if (totalPlanned > wakingSeconds) {
        const err = new Error(
          `Total planned time (${totalPlanned}s) cannot exceed available waking time (${wakingSeconds}s)`,
        );
        (err as any).statusCode = 400;
        throw err;
      }

      // Update or insert items
      const existingItems = await db
        .select({
          id: planItems.id,
          dailyPlanId: planItems.dailyPlanId,
          categoryId: planItems.categoryId,
          categoryName: categories.name,
          plannedSeconds: planItems.plannedSeconds,
          remainingSeconds: planItems.remainingSeconds,
          startedAt: planItems.startedAt,
        })
        .from(planItems)
        .innerJoin(categories, eq(planItems.categoryId, categories.id))
        .where(eq(planItems.dailyPlanId, planId));

      const existingItemIds = existingItems.map((i) => i.id);
      const allEntries =
        existingItemIds.length > 0
          ? await db
              .select({
                planItemId: timeEntries.planItemId,
                startedAt: timeEntries.startedAt,
                endedAt: timeEntries.endedAt,
              })
              .from(timeEntries)
              .where(
                and(
                  eq(timeEntries.userId, userId),
                  inArray(timeEntries.planItemId, existingItemIds),
                ),
              )
          : [];

      const now = new Date();
      const existingMap = new Map(existingItems.map((i) => [i.categoryId, i]));
      const updatedCategoryIds: string[] = [];

      for (const item of data.items) {
        updatedCategoryIds.push(item.categoryId);
        const existingItem = existingMap.get(item.categoryId);

        if (existingItem) {
          // Calculate time already used today for this category
          const itemEntries = allEntries.filter(
            (e) => e.planItemId === existingItem.id,
          );
          const actualFromEntries = calculateActualSeconds(itemEntries, now);
          const elapsedFromRemaining =
            existingItem.plannedSeconds -
            existingItem.remainingSeconds +
            (existingItem.startedAt
              ? Math.max(
                  0,
                  Math.floor(
                    (now.getTime() - new Date(existingItem.startedAt).getTime()) /
                      1000,
                  ),
                )
              : 0);
          const usedSeconds = Math.max(actualFromEntries, elapsedFromRemaining);
          const minPlannedSeconds = calculateMinimumPlannedSeconds(usedSeconds);

          // Enforce minimum planned time rule:
          // A category cannot be planned below the time already used today (rounded UP to 30 minutes).
          if (item.plannedSeconds < minPlannedSeconds) {
            const usedStr = formatDurationFriendly(usedSeconds);
            const minStr = formatDurationFriendly(minPlannedSeconds);
            const err = new Error(
              `You've already used ${usedStr} here, so ${minStr} is the minimum.`,
            );
            (err as any).statusCode = 400;
            throw err;
          }

          // Rule 6: Editing planned_seconds while a timer runs:
          // change remaining by the difference (new minus old) and do NOT restart or reset the running timer
          const newRemaining = calculatePlannedSecondsChange(
            existingItem.remainingSeconds,
            existingItem.plannedSeconds,
            item.plannedSeconds,
          );

          await db
            .update(planItems)
            .set({
              plannedSeconds: item.plannedSeconds,
              remainingSeconds: newRemaining,
              // startedAt is NOT updated here - running timer continues undisturbed
            })
            .where(eq(planItems.id, existingItem.id));
        } else {
          await db.insert(planItems).values({
            dailyPlanId: planId,
            userId,
            categoryId: item.categoryId,
            plannedSeconds: item.plannedSeconds,
            remainingSeconds: item.plannedSeconds,
          });
        }
      }

      // Check if removing any item with a running timer or used time
      const itemsToRemove = existingItems.filter(
        (i) => !updatedCategoryIds.includes(i.categoryId),
      );

      const runningRemovedItem = itemsToRemove.find(
        (i) => i.startedAt !== null,
      );
      if (runningRemovedItem) {
        const err = new Error(
          'Cannot remove a category with an active running timer. Pause it first.',
        );
        (err as any).statusCode = 400;
        throw err;
      }

      for (const removedItem of itemsToRemove) {
        const itemEntries = allEntries.filter(
          (e) => e.planItemId === removedItem.id,
        );
        const actualFromEntries = calculateActualSeconds(itemEntries, now);
        const elapsedFromRemaining =
          removedItem.plannedSeconds - removedItem.remainingSeconds;
        const usedSeconds = Math.max(actualFromEntries, elapsedFromRemaining);
        if (usedSeconds > 0) {
          const usedStr = formatDurationFriendly(usedSeconds);
          const minStr = formatDurationFriendly(calculateMinimumPlannedSeconds(usedSeconds));
          const err = new Error(
            `You've already used ${usedStr} here, so ${minStr} is the minimum.`,
          );
          (err as any).statusCode = 400;
          throw err;
        }
      }

      if (itemsToRemove.length > 0) {
        await db
          .delete(planItems)
          .where(
            and(
              eq(planItems.dailyPlanId, planId),
              notInArray(
                planItems.categoryId,
                updatedCategoryIds,
              ),
            ),
          );
      }
    }

    return this.getPlanById(userId, planId);
  }

  /**
   * Rule 8: Actual time per category = sum of its time_entries (an open entry counts until now).
   * Generates summary of planned vs actual per category for a given date.
   */
  static async getSummary(
    userId: string,
    dateStr: string,
  ): Promise<PlanSummary> {
    const now = new Date();

    const [plan] = await db
      .select()
      .from(dailyPlans)
      .where(
        and(eq(dailyPlans.userId, userId), eq(dailyPlans.planDate, dateStr)),
      )
      .limit(1);

    if (!plan) {
      return {
        planId: null,
        planDate: dateStr,
        wakingSeconds: 0,
        totalPlannedSeconds: 0,
        totalActualSeconds: 0,
        categories: [],
      };
    }

    const items = await this.getItemsForPlan(plan.id);
    if (items.length === 0) {
      return {
        planId: plan.id,
        planDate: plan.planDate,
        wakingSeconds: plan.wakingSeconds,
        totalPlannedSeconds: 0,
        totalActualSeconds: 0,
        categories: [],
      };
    }

    const itemIds = items.map((i) => i.id);
    const entries = await db
      .select({
        planItemId: timeEntries.planItemId,
        startedAt: timeEntries.startedAt,
        endedAt: timeEntries.endedAt,
      })
      .from(timeEntries)
      .where(
        and(
          eq(timeEntries.userId, userId),
          inArray(timeEntries.planItemId, itemIds),
        ),
      );

    const categoriesSummary: CategorySummary[] = items.map((item) => {
      const itemEntries = entries.filter((e) => e.planItemId === item.id);
      const actualSeconds = calculateActualSeconds(itemEntries, now);
      const activeElapsed = item.startedAt
        ? Math.max(
            0,
            Math.floor(
              (now.getTime() - new Date(item.startedAt).getTime()) / 1000,
            ),
          )
        : 0;

      const currentRemaining = item.remainingSeconds - activeElapsed;
      const overtimeSeconds = currentRemaining < 0 ? Math.abs(currentRemaining) : 0;

      return {
        categoryId: item.categoryId,
        categoryName: item.categoryName,
        categoryDescription: item.categoryDescription,
        categoryColor: item.categoryColor,
        categoryIcon: item.categoryIcon,
        plannedSeconds: item.plannedSeconds,
        actualSeconds,
        remainingSeconds: currentRemaining,
        overtimeSeconds,
        isRunning: item.startedAt !== null,
        startedAt: item.startedAt,
      };
    });

    const totalPlannedSeconds = categoriesSummary.reduce(
      (sum, c) => sum + c.plannedSeconds,
      0,
    );
    const totalActualSeconds = categoriesSummary.reduce(
      (sum, c) => sum + c.actualSeconds,
      0,
    );

    return {
      planId: plan.id,
      planDate: plan.planDate,
      wakingSeconds: plan.wakingSeconds,
      totalPlannedSeconds,
      totalActualSeconds,
      categories: categoriesSummary,
    };
  }

  static async getSummaryById(
    userId: string,
    planId: string,
  ): Promise<PlanSummary> {
    const plan = await this.getPlanById(userId, planId);
    return this.getSummary(userId, plan.planDate);
  }
}
