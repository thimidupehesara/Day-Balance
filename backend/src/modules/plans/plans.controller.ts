import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { PlansService } from './plans.service';
import {
  createPlanSchema,
  updatePlanSchema,
  planDateQuerySchema,
} from './plans.validation';

export class PlansController {
  static async createPlan(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const serverTime = new Date().toISOString();
      const validated = createPlanSchema.parse(req.body);
      const plan = await PlansService.createPlan(userId, validated);

      const status = plan.isExisting ? 200 : 201;
      const message = plan.isExisting
        ? 'Plan already exists for this date, returning existing plan'
        : 'Plan created successfully';

      res.status(status).json({
        message,
        data: { plan, serverTime },
        serverTime,
      });
    } catch (err: any) {
      const serverTime = new Date().toISOString();
      if (err instanceof ZodError) {
        res.status(400).json({
          error: 'Validation failed',
          details: err.flatten().fieldErrors,
          serverTime,
        });
        return;
      }
      if (err.statusCode) {
        res.status(err.statusCode).json({ error: err.message, serverTime });
        return;
      }
      next(err);
    }
  }

  static async getToday(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const serverTime = new Date().toISOString();
      const query = planDateQuerySchema.parse(req.query);
      const dateStr =
        query.date || serverTime.split('T')[0];

      const plan = await PlansService.getPlanByDate(userId, dateStr);

      res.status(200).json({
        data: { plan, serverTime },
        serverTime,
      });
    } catch (err: any) {
      const serverTime = new Date().toISOString();
      if (err instanceof ZodError) {
        res.status(400).json({
          error: 'Validation failed',
          details: err.flatten().fieldErrors,
          serverTime,
        });
        return;
      }
      next(err);
    }
  }

  static async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const serverTime = new Date().toISOString();
      const planId = req.params.id as string;
      const plan = await PlansService.getPlanById(userId, planId);

      res.status(200).json({
        data: { plan, serverTime },
        serverTime,
      });
    } catch (err: any) {
      const serverTime = new Date().toISOString();
      if (err.statusCode) {
        res.status(err.statusCode).json({ error: err.message, serverTime });
        return;
      }
      next(err);
    }
  }

  static async updatePlan(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const serverTime = new Date().toISOString();
      const planId = req.params.id as string;
      const validated = updatePlanSchema.parse(req.body);
      const updatedPlan = await PlansService.updatePlan(
        userId,
        planId,
        validated,
      );

      res.status(200).json({
        message: 'Plan updated successfully',
        data: { plan: updatedPlan, serverTime },
        serverTime,
      });
    } catch (err: any) {
      const serverTime = new Date().toISOString();
      if (err instanceof ZodError) {
        res.status(400).json({
          error: 'Validation failed',
          details: err.flatten().fieldErrors,
          serverTime,
        });
        return;
      }
      if (err.statusCode) {
        res.status(err.statusCode).json({ error: err.message, serverTime });
        return;
      }
      next(err);
    }
  }

  static async getSummary(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const serverTime = new Date().toISOString();
      const query = planDateQuerySchema.parse(req.query);
      const dateStr = query.date || serverTime.split('T')[0];

      const summary = await PlansService.getSummary(userId, dateStr);

      res.status(200).json({
        data: { summary, serverTime },
        serverTime,
      });
    } catch (err: any) {
      const serverTime = new Date().toISOString();
      if (err instanceof ZodError) {
        res.status(400).json({
          error: 'Validation failed',
          details: err.flatten().fieldErrors,
          serverTime,
        });
        return;
      }
      if (err.statusCode) {
        res.status(err.statusCode).json({ error: err.message, serverTime });
        return;
      }
      next(err);
    }
  }

  static async getSummaryById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const serverTime = new Date().toISOString();
      const planId = req.params.id as string;
      const summary = await PlansService.getSummaryById(userId, planId);

      res.status(200).json({
        data: { summary, serverTime },
        serverTime,
      });
    } catch (err: any) {
      const serverTime = new Date().toISOString();
      if (err.statusCode) {
        res.status(err.statusCode).json({ error: err.message, serverTime });
        return;
      }
      next(err);
    }
  }
}
