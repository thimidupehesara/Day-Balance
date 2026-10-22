import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { TimerService } from './timer.service';
import {
  startTimerSchema,
  pauseTimerSchema,
  resumeTimerSchema,
  timerStatusQuerySchema,
} from './timer.validation';

export class TimerController {
  static async start(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const validated = startTimerSchema.parse(req.body);
      const result = await TimerService.startTimer(
        userId,
        validated.planItemId,
      );

      res.status(200).json({
        message: result.isAlreadyRunning
          ? 'Timer is already running'
          : 'Timer started successfully',
        data: result,
        serverTime: result.serverTime,
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

  static async pause(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const validated = pauseTimerSchema.parse(req.body || {});
      const result = await TimerService.pauseTimer(userId, validated.planItemId);

      res.status(200).json({
        message: 'Timer paused successfully',
        data: result,
        serverTime: result.serverTime,
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

  static async resume(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const validated = resumeTimerSchema.parse(req.body);
      const result = await TimerService.resumeTimer(
        userId,
        validated.planItemId,
      );

      res.status(200).json({
        message: 'Timer resumed successfully',
        data: result,
        serverTime: result.serverTime,
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

  static async getStatus(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const query = timerStatusQuerySchema.parse(req.query);
      const serverTime = new Date().toISOString();
      const dateStr = query.date || serverTime.split('T')[0];

      const status = await TimerService.getStatus(userId, dateStr);

      res.status(200).json({
        data: status,
        serverTime: status.serverTime,
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
}
