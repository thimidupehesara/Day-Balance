import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { CategoriesService } from './categories.service';
import { updateUserCategoriesSchema, createCategorySchema } from './categories.validation';

export class CategoriesController {
  static async getAvailable(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.userId) { res.status(401).json({ error: 'Unauthorized' }); return; }
      res.json({ data: { categories: await CategoriesService.getAvailableCategories(req.userId) } });
    } catch (err) { next(err); }
  }

  static async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.userId) { res.status(401).json({ error: 'Unauthorized' }); return; }
      const input = createCategorySchema.parse(req.body);
      const category = await CategoriesService.createCustomCategory(req.userId, input);
      res.status(201).json({ data: { category } });
    } catch (err) {
      if (err instanceof ZodError) {
        res.status(400).json({ error: 'Validation failed', details: err.flatten().fieldErrors });
        return;
      }
      if (err instanceof Error && 'statusCode' in err && typeof err.statusCode === 'number') {
        res.status(err.statusCode).json({ error: err.message });
        return;
      }
      next(err);
    }
  }
  static async getAll(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const allCategories = await CategoriesService.getAllCategories();
      res.status(200).json({
        data: { categories: allCategories },
      });
    } catch (err) {
      next(err);
    }
  }

  static async getMine(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const userCats = await CategoriesService.getUserCategories(userId);
      res.status(200).json({
        data: { categories: userCats },
      });
    } catch (err) {
      next(err);
    }
  }

  static async setMine(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const validated = updateUserCategoriesSchema.parse(req.body);
      const updated = await CategoriesService.setUserCategories(
        userId,
        validated.categoryIds,
      );

      res.status(200).json({
        message: 'User categories updated successfully',
        data: { categories: updated },
      });
    } catch (err: any) {
      if (err instanceof ZodError) {
        res.status(400).json({
          error: 'Validation failed',
          details: err.flatten().fieldErrors,
        });
        return;
      }
      if (err.statusCode) {
        res.status(err.statusCode).json({ error: err.message });
        return;
      }
      next(err);
    }
  }
}
