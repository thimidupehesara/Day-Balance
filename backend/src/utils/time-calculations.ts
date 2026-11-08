/**
 * Utility functions for time calculations in Day-Balance.
 * Handles waking seconds computation, timer pause math, planned seconds updates,
 * and actual duration aggregation from time entries.
 */

export interface TimeEntryLike {
  startedAt: Date | string;
  endedAt: Date | string | null;
}

/**
 * Calculates waking seconds for a day from a user's profile.
 * waking_seconds = (gross waking minutes - routine minutes) * 60
 * Supports crossing midnight (e.g., wake at 07:00, bedtime at 01:00).
 * Defaults: wakeTime = 07:00:00, bedtime = 23:00:00, routineMinutes = 0.
 */
export function calculateWakingSeconds(
  wakeTime?: string | null,
  bedtime?: string | null,
  routineMinutes?: number | null,
): number {
  const wakeStr = wakeTime || '07:00:00';
  const bedStr = bedtime || '23:00:00';

  const [wakeH, wakeM] = wakeStr.split(':').map((v) => parseInt(v, 10) || 0);
  const [bedH, bedM] = bedStr.split(':').map((v) => parseInt(v, 10) || 0);

  const wakeMinutes = (wakeH * 60 + wakeM) % 1440;
  const bedMinutes = (bedH * 60 + bedM) % 1440;

  // If bedtime is <= wakeTime, user goes to bed past midnight (e.g. 7 AM to 1 AM next day)
  const grossWakingMinutes =
    bedMinutes > wakeMinutes
      ? bedMinutes - wakeMinutes
      : bedMinutes + 1440 - wakeMinutes;

  const routineM = Math.max(0, routineMinutes || 0);
  const netWakingMinutes = Math.max(0, grossWakingMinutes - routineM);

  return netWakingMinutes * 60;
}

/**
 * Computes elapsed seconds and remaining seconds when pausing a timer.
 * remaining_seconds = remaining_seconds - (now - started_at)
 * Can result in negative remaining_seconds, representing overtime.
 */
export function calculateTimerPauseRemaining(
  currentRemainingSeconds: number,
  startedAt: Date | string,
  now: Date = new Date(),
): {
  elapsedSeconds: number;
  newRemainingSeconds: number;
  isOvertime: boolean;
  overtimeSeconds: number;
} {
  const startedMs = new Date(startedAt).getTime();
  const nowMs = now.getTime();
  const elapsedSeconds = Math.max(0, Math.floor((nowMs - startedMs) / 1000));
  const newRemainingSeconds = currentRemainingSeconds - elapsedSeconds;
  const isOvertime = newRemainingSeconds < 0;
  const overtimeSeconds = isOvertime ? Math.abs(newRemainingSeconds) : 0;

  return {
    elapsedSeconds,
    newRemainingSeconds,
    isOvertime,
    overtimeSeconds,
  };
}

/**
 * Computes the new remaining seconds when planned_seconds is updated.
 * difference = newPlanned - oldPlanned
 * newRemaining = currentRemaining + difference
 * Preserves elapsed time whether timer is running or paused.
 */
export function calculatePlannedSecondsChange(
  currentRemainingSeconds: number,
  oldPlannedSeconds: number,
  newPlannedSeconds: number,
): number {
  const diff = newPlannedSeconds - oldPlannedSeconds;
  return currentRemainingSeconds + diff;
}

/**
 * Calculates total actual seconds spent from time entries.
 * For completed entries: endedAt - startedAt
 * For open entries (endedAt is null): now - startedAt
 */
export function calculateActualSeconds(
  entries: TimeEntryLike[],
  now: Date = new Date(),
): number {
  const nowMs = now.getTime();

  return entries.reduce((total, entry) => {
    const startMs = new Date(entry.startedAt).getTime();
    const endMs = entry.endedAt ? new Date(entry.endedAt).getTime() : nowMs;
    const duration = Math.max(0, Math.floor((endMs - startMs) / 1000));
    return total + duration;
  }, 0);
}

/**
 * Calculates the minimum planned seconds allowed based on time already used today.
 * Rounded up to the nearest 30-minute interval (1800s).
 */
export function calculateMinimumPlannedSeconds(usedSeconds: number): number {
  if (usedSeconds <= 0) return 0;
  return Math.ceil(usedSeconds / 1800) * 1800;
}

/**
 * Formats seconds into a human-friendly duration string (e.g., "3h", "1h 30m", "45m").
 */
export function formatDurationFriendly(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  if (h > 0 && m > 0) return `${h}h ${m}m`;
  if (h > 0) return `${h}h`;
  return `${m}m`;
}

