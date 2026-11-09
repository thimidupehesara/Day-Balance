import { eq, inArray, asc, and, or, like, notLike, sql } from 'drizzle-orm';
import { randomUUID } from 'node:crypto';
import { db } from '../../db/connection';
import { categories, userCategories, users } from '../../db/schema';
import { canUseCategory, customCategoryPrefix } from './category-access';
import { CreateCategoryInput } from './categories.validation';

export interface Category {
  id: string;
  name: string;
  description: string;
  color: string;
  icon: string;
  sortOrder: number;
}

export class CategoriesService {
  static async getAllCategories(): Promise<Category[]> {
    return db.select().from(categories).where(notLike(categories.id, 'custom:%')).orderBy(asc(categories.sortOrder));
  }

  static async getAvailableCategories(userId: string): Promise<Category[]> {
    return db.select().from(categories).where(or(
      notLike(categories.id, 'custom:%'),
      like(categories.id, `${customCategoryPrefix(userId)}%`),
    )).orderBy(asc(categories.sortOrder), asc(categories.name));
  }

  static async validateCategoryAccess(userId: string, ids: string[]): Promise<void> {
    const uniqueIds = [...new Set(ids)];
    if (!uniqueIds.length) return;
    const existing = await db.select({ id: categories.id }).from(categories)
      .where(inArray(categories.id, uniqueIds));
    if (existing.length !== uniqueIds.length || uniqueIds.some(id => !canUseCategory(userId, id))) {
      throw Object.assign(new Error('One or more invalid category IDs provided'), { statusCode: 400 });
    }
  }

  static async createCustomCategory(userId: string, input: CreateCategoryInput): Promise<Category> {
    return db.transaction(async tx => {
      // Serialize creations for this user so duplicate names and limits hold under concurrency.
      await tx.select({ id: users.id }).from(users).where(eq(users.id, userId)).for('update');
      const owned = await tx.select().from(categories)
        .where(like(categories.id, `${customCategoryPrefix(userId)}%`));
      if (owned.length >= 20) throw Object.assign(new Error('You can add up to 20 custom categories'), { statusCode: 400 });
      const duplicate = await tx.select({ id: categories.id }).from(categories).where(and(
        or(notLike(categories.id, 'custom:%'), like(categories.id, `${customCategoryPrefix(userId)}%`)),
        sql`lower(${categories.name}) = lower(${input.name})`,
      ));
      if (duplicate.length) throw Object.assign(new Error('A category with this name already exists'), { statusCode: 409 });
      const [category] = await tx.insert(categories).values({
        id: `${customCategoryPrefix(userId)}${randomUUID()}`,
        ...input, icon: 'category', sortOrder: 100 + owned.length,
      }).returning();
      await tx.insert(userCategories).values({ userId, categoryId: category.id });
      return category;
    });
  }

  static async getUserCategories(userId: string): Promise<Category[]> {
    return db
      .select({
        id: categories.id,
        name: categories.name,
        description: categories.description,
        color: categories.color,
        icon: categories.icon,
        sortOrder: categories.sortOrder,
      })
      .from(userCategories)
      .innerJoin(categories, eq(userCategories.categoryId, categories.id))
      .where(eq(userCategories.userId, userId))
      .orderBy(asc(categories.sortOrder));
  }

  static async setUserCategories(
    userId: string,
    categoryIds: string[],
  ): Promise<Category[]> {
    const uniqueIds = Array.from(new Set(categoryIds));

    await this.validateCategoryAccess(userId, uniqueIds);

    // Replace user's selected categories
    await db.transaction(async tx => {
      await tx.select({ id: users.id }).from(users).where(eq(users.id, userId)).for('update');
      await tx.delete(userCategories).where(eq(userCategories.userId, userId));
      if (uniqueIds.length > 0) {
      await tx.insert(userCategories).values(
        uniqueIds.map((categoryId) => ({
          userId,
          categoryId,
        })),
      );
      }
    });

    return this.getUserCategories(userId);
  }
}
