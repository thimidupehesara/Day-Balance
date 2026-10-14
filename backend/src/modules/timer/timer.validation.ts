import { z } from 'zod';

const dateRegex = /^\d{4}-\d{2}-\d{2}$/;

export const startTimerSchema = z.object({
  planItemId: z.string().uuid('Invalid planItemId UUID'),
});

export const pauseTimerSchema = z.object({
  planItemId: z.string().uuid('Invalid planItemId UUID').optional(),
});

export const resumeTimerSchema = z.object({
  planItemId: z.string().uuid('Invalid planItemId UUID'),
});

export const timerStatusQuerySchema = z.object({
  date: z
    .string()
    .regex(dateRegex, 'date must be in YYYY-MM-DD format')
    .optional(),
});

export type StartTimerInput = z.infer<typeof startTimerSchema>;
export type PauseTimerInput = z.infer<typeof pauseTimerSchema>;
export type ResumeTimerInput = z.infer<typeof resumeTimerSchema>;
export type TimerStatusQueryInput = z.infer<typeof timerStatusQuerySchema>;
