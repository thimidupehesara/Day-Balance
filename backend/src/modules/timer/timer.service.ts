import { eq, and, isNotNull, isNull, asc } from 'drizzle-orm';
import { sql } from 'drizzle-orm';
import { db } from '../../db/connection';
import {
  planItems,
  timeEntries,
  dailyPlans,
  categories,
} from '../../db/schema';
import { PlanItemWithCategory } from '../plans/plans.service';
import { calculateTimerPauseRemaining } from '../../utils/time-calculations';

export interface TimerStatus {
  serverTime: string;
  planId: string | null;
  planDate: string | null;
  activeItem: PlanItemWithCategory | null;
  items: PlanItemWithCategory[];
}

export interface StartTimerResult {
  activeItem: PlanItemWithCategory;
  autoPausedItem: PlanItemWithCategory | null;
  serverTime: string;
  isAlreadyRunning: boolean;
}

export interface PauseTimerResult {
  pausedItem: PlanItemWithCategory;
  elapsedSeconds: number;
  isOvertime: boolean;
  overtimeSeconds: number;
  serverTime: string;
}

export class TimerService {
  private static async getItemsForPlan(
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

  /**
   * Rule 4: Start timer on an item.
   * Sets started_at, opens a time_entries row, and AUTO-PAUSES any other running
   * item for that user in ONE database transaction with concurrency locking.
   * Rule 10: Starting an already running item is idempotent.
   */
  static async startTimer(
    userId: string,
    planItemId: string,
  ): Promise<StartTimerResult> {
    return await db.transaction(async (tx) => {
      // 1. Acquire exclusive lock on user row to serialize concurrent timer actions for this user
      await tx.execute(
        sql`SELECT id FROM users WHERE id = ${userId}::uuid FOR UPDATE`,
      );

      const now = new Date();

      // 2. Verify target item belongs to user
      const [targetItem] = await tx
        .select()
        .from(planItems)
        .where(and(eq(planItems.id, planItemId), eq(planItems.userId, userId)))
        .limit(1);

      if (!targetItem) {
        const err = new Error('Plan item not found');
        (err as any).statusCode = 404;
        throw err;
      }

      // 3. Rule 10: Check if parent plan is for a past date
      const [parentPlan] = await tx
        .select()
        .from(dailyPlans)
        .where(eq(dailyPlans.id, targetItem.dailyPlanId))
        .limit(1);

      const todayStr = now.toISOString().split('T')[0];
      if (parentPlan && parentPlan.planDate < todayStr) {
        const err = new Error("Cannot start timer for a past date's plan");
        (err as any).statusCode = 400;
        throw err;
      }

      // 4. Rule 10: Idempotent - if this item is already running, return it unchanged
      if (targetItem.startedAt) {
        const [alreadyRunningWithCategory] = await tx
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
          .where(eq(planItems.id, planItemId))
          .limit(1);

        return {
          activeItem: alreadyRunningWithCategory,
          autoPausedItem: null,
          serverTime: now.toISOString(),
          isAlreadyRunning: true,
        };
      }

      // 5. Rule 4: Auto-pause any currently running item for that user in ONE transaction
      const [runningItem] = await tx
        .select()
        .from(planItems)
        .where(and(eq(planItems.userId, userId), isNotNull(planItems.startedAt)))
        .limit(1);

      let autoPausedItem: PlanItemWithCategory | null = null;

      if (runningItem && runningItem.startedAt) {
        const pauseCalc = calculateTimerPauseRemaining(
          runningItem.remainingSeconds,
          runningItem.startedAt,
          now,
        );

        // Update running item remainingSeconds (can be negative for overtime) and clear started_at
        await tx
          .update(planItems)
          .set({
            remainingSeconds: pauseCalc.newRemainingSeconds,
            startedAt: null,
          })
          .where(eq(planItems.id, runningItem.id));

        // Close open time entry
        await tx
          .update(timeEntries)
          .set({ endedAt: now })
          .where(
            and(
              eq(timeEntries.planItemId, runningItem.id),
              eq(timeEntries.userId, userId),
              isNull(timeEntries.endedAt),
            ),
          );

        const [pausedWithCategory] = await tx
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
          .where(eq(planItems.id, runningItem.id))
          .limit(1);

        autoPausedItem = pausedWithCategory || null;
      }

      // 6. Start the target item
      await tx
        .update(planItems)
        .set({ startedAt: now })
        .where(eq(planItems.id, planItemId));

      // 7. Open a new time entry
      await tx.insert(timeEntries).values({
        planItemId,
        userId,
        startedAt: now,
        endedAt: null,
      });

      // 8. Fetch updated active item
      const [activeItem] = await tx
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
        .where(eq(planItems.id, planItemId))
        .limit(1);

      return {
        activeItem,
        autoPausedItem,
        serverTime: now.toISOString(),
        isAlreadyRunning: false,
      };
    });
  }

  /**
   * Rule 5: Pause timer.
   * remaining_seconds = remaining_seconds - (now - started_at), started_at cleared, entry closed.
   * remaining_seconds may go NEGATIVE (overtime).
   * Rule 10: Clear error (400) if no timer is running.
   */
  static async pauseTimer(
    userId: string,
    planItemId?: string,
  ): Promise<PauseTimerResult> {
    return await db.transaction(async (tx) => {
      // Lock user row
      await tx.execute(
        sql`SELECT id FROM users WHERE id = ${userId}::uuid FOR UPDATE`,
      );

      if (planItemId) {
        const [targetItem] = await tx
          .select()
          .from(planItems)
          .where(and(eq(planItems.id, planItemId), eq(planItems.userId, userId)))
          .limit(1);

        if (!targetItem) {
          const err = new Error('Plan item not found');
          (err as any).statusCode = 404;
          throw err;
        }

        if (!targetItem.startedAt) {
          const err = new Error('Plan item is not currently running');
          (err as any).statusCode = 400;
          throw err;
        }
      }

      const [runningItem] = await tx
        .select()
        .from(planItems)
        .where(and(eq(planItems.userId, userId), isNotNull(planItems.startedAt)))
        .limit(1);

      if (!runningItem || !runningItem.startedAt) {
        const err = new Error('No active timer is currently running');
        (err as any).statusCode = 400;
        throw err;
      }

      if (planItemId && runningItem.id !== planItemId) {
        const err = new Error('Specified plan item is not currently running');
        (err as any).statusCode = 400;
        throw err;
      }

      const now = new Date();
      const pauseCalc = calculateTimerPauseRemaining(
        runningItem.remainingSeconds,
        runningItem.startedAt,
        now,
      );

      // Update plan item: save updated remaining_seconds and clear started_at
      await tx
        .update(planItems)
        .set({
          remainingSeconds: pauseCalc.newRemainingSeconds,
          startedAt: null,
        })
        .where(eq(planItems.id, runningItem.id));

      // Close open time entry
      await tx
        .update(timeEntries)
        .set({ endedAt: now })
        .where(
          and(
            eq(timeEntries.planItemId, runningItem.id),
            eq(timeEntries.userId, userId),
            isNull(timeEntries.endedAt),
          ),
        );

      const [pausedItem] = await tx
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
        .where(eq(planItems.id, runningItem.id))
        .limit(1);

      return {
        pausedItem,
        elapsedSeconds: pauseCalc.elapsedSeconds,
        isOvertime: pauseCalc.isOvertime,
        overtimeSeconds: pauseCalc.overtimeSeconds,
        serverTime: now.toISOString(),
      };
    });
  }

  /**
   * Resume timer on an item (calls startTimer).
   */
  static async resumeTimer(
    userId: string,
    planItemId: string,
  ): Promise<StartTimerResult> {
    return this.startTimer(userId, planItemId);
  }

  static async getStatus(
    userId: string,
    dateStr: string,
  ): Promise<TimerStatus> {
    const serverTime = new Date().toISOString();

    const [plan] = await db
      .select()
      .from(dailyPlans)
      .where(
        and(eq(dailyPlans.userId, userId), eq(dailyPlans.planDate, dateStr)),
      )
      .limit(1);

    if (!plan) {
      return {
        serverTime,
        planId: null,
        planDate: dateStr,
        activeItem: null,
        items: [],
      };
    }

    const items = await this.getItemsForPlan(plan.id);
    const activeItem = items.find((item) => item.startedAt !== null) || null;

    return {
      serverTime,
      planId: plan.id,
      planDate: plan.planDate,
      activeItem,
      items,
    };
  }
}
