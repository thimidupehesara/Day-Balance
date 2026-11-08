import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  calculateWakingSeconds,
  calculateTimerPauseRemaining,
  calculatePlannedSecondsChange,
  calculateActualSeconds,
  calculateMinimumPlannedSeconds,
  formatDurationFriendly,
} from '../utils/time-calculations';

describe('Timer & Plan Math Unit Tests', () => {
  describe('Rule 2: Waking seconds calculation', () => {
    it('calculates standard waking hours (07:00 to 23:00, 0 routine) = 16h = 57600s', () => {
      const waking = calculateWakingSeconds('07:00:00', '23:00:00', 0);
      assert.equal(waking, 16 * 3600);
      assert.equal(waking, 57600);
    });

    it('calculates midnight crossing (07:00 to 01:00 next day, 0 routine) = 18h = 64800s', () => {
      const waking = calculateWakingSeconds('07:00:00', '01:00:00', 0);
      assert.equal(waking, 18 * 3600);
      assert.equal(waking, 64800);
    });

    it('subtracts routine minutes correctly (07:00 to 23:00, 90 routine) = 14.5h = 52200s', () => {
      const waking = calculateWakingSeconds('07:00:00', '23:00:00', 90);
      assert.equal(waking, 14.5 * 3600);
      assert.equal(waking, 52200);
    });

    it('uses fallback defaults if profile fields are null or undefined', () => {
      const waking = calculateWakingSeconds(null, null, null);
      assert.equal(waking, 16 * 3600);
    });

    it('clamps net waking seconds to zero if routine exceeds awake hours', () => {
      const waking = calculateWakingSeconds('07:00:00', '10:00:00', 300); // 3h awake - 5h routine
      assert.equal(waking, 0);
    });
  });

  describe('Rule 4: Auto-pause when starting another item', () => {
    it('computes auto-pause remaining time for previously running item A when B starts', () => {
      const itemA = {
        id: 'item-a',
        plannedSeconds: 7200,
        remainingSeconds: 7200,
        startedAt: new Date('2026-10-14T14:00:00Z'),
      };

      const now = new Date('2026-10-14T14:30:00Z'); // 30 min = 1800s later, user starts item B
      const pauseA = calculateTimerPauseRemaining(
        itemA.remainingSeconds,
        itemA.startedAt,
        now,
      );

      // Item A is paused: remaining is reduced by 1800s
      assert.equal(pauseA.elapsedSeconds, 1800);
      assert.equal(pauseA.newRemainingSeconds, 5400);
      assert.equal(pauseA.isOvertime, false);

      // Invariant: only one item will have startedAt != null
      const updatedItemA = { ...itemA, remainingSeconds: pauseA.newRemainingSeconds, startedAt: null };
      const startedItemB = { id: 'item-b', remainingSeconds: 3600, startedAt: now };

      const runningCount = [updatedItemA, startedItemB].filter((i) => i.startedAt !== null).length;
      assert.equal(runningCount, 1);
    });
  });

  describe('Rule 5: Pause & Overtime math', () => {
    it('correctly deducts elapsed time from remaining_seconds', () => {
      const started = new Date('2026-10-14T10:00:00Z');
      const now = new Date('2026-10-14T10:15:00Z'); // 15 min = 900s
      const result = calculateTimerPauseRemaining(3600, started, now);

      assert.equal(result.elapsedSeconds, 900);
      assert.equal(result.newRemainingSeconds, 2700);
      assert.equal(result.isOvertime, false);
      assert.equal(result.overtimeSeconds, 0);
    });

    it('allows remaining_seconds to go negative for overtime', () => {
      const started = new Date('2026-10-14T10:00:00Z');
      const now = new Date('2026-10-14T10:45:00Z'); // 45 min = 2700s
      const result = calculateTimerPauseRemaining(1800, started, now); // planned was 1800s

      assert.equal(result.elapsedSeconds, 2700);
      assert.equal(result.newRemainingSeconds, -900);
      assert.equal(result.isOvertime, true);
      assert.equal(result.overtimeSeconds, 900);
    });
  });

  describe('Rule 6: Editing planned_seconds while running', () => {
    it('adjusts remaining_seconds by the difference (new minus old) without touching started_at', () => {
      const oldPlanned = 3600;
      const currentRemaining = 3000; // 600s already elapsed
      const newPlanned = 5400; // +1800s added

      const newRemaining = calculatePlannedSecondsChange(
        currentRemaining,
        oldPlanned,
        newPlanned,
      );

      assert.equal(newRemaining, 4800);
      // Verify total elapsed time is preserved: 5400 - 4800 = 600s
      assert.equal(newPlanned - newRemaining, 600);
    });

    it('handles decreasing planned_seconds into overtime', () => {
      const oldPlanned = 3600;
      const currentRemaining = 600; // 3000s elapsed
      const newPlanned = 1800; // reduced by 1800s

      const newRemaining = calculatePlannedSecondsChange(
        currentRemaining,
        oldPlanned,
        newPlanned,
      );

      assert.equal(newRemaining, -1200); // 3000 elapsed vs 1800 planned = 1200s overtime
    });
  });

  describe('Rule 7: Timer running past midnight', () => {
    it('keeps counting toward the plan it started on across the midnight boundary', () => {
      const startedAtNight = new Date('2026-10-14T23:45:00.000Z');
      const pausedNextMorning = new Date('2026-10-15T00:15:00.000Z'); // 30 minutes later across midnight

      const result = calculateTimerPauseRemaining(
        3600,
        startedAtNight,
        pausedNextMorning,
      );

      assert.equal(result.elapsedSeconds, 1800); // exactly 30 min (1800s)
      assert.equal(result.newRemainingSeconds, 1800);
      assert.equal(result.isOvertime, false);
    });

    it('crosses midnight into overtime correctly', () => {
      const startedAtNight = new Date('2026-10-14T23:45:00.000Z');
      const pausedNextMorning = new Date('2026-10-15T01:00:00.000Z'); // 75 minutes = 4500s

      const result = calculateTimerPauseRemaining(
        1800, // 30 min planned
        startedAtNight,
        pausedNextMorning,
      );

      assert.equal(result.elapsedSeconds, 4500);
      assert.equal(result.newRemainingSeconds, -2700); // 45 min overtime
      assert.equal(result.isOvertime, true);
      assert.equal(result.overtimeSeconds, 2700);
    });
  });

  describe('Rule 8: Actual time aggregation', () => {
    it('sums completed time entries and active open entry', () => {
      const now = new Date('2026-10-14T12:00:00Z');
      const entries = [
        {
          startedAt: new Date('2026-10-14T09:00:00Z'),
          endedAt: new Date('2026-10-14T09:30:00Z'), // 30 min = 1800s
        },
        {
          startedAt: new Date('2026-10-14T10:00:00Z'),
          endedAt: new Date('2026-10-14T10:45:00Z'), // 45 min = 2700s
        },
        {
          startedAt: new Date('2026-10-14T11:45:00Z'),
          endedAt: null, // open entry: 11:45 to 12:00 = 15 min = 900s
        },
      ];

      const actualSeconds = calculateActualSeconds(entries, now);
      assert.equal(actualSeconds, 1800 + 2700 + 900); // 5400s = 1.5h
    });
  });

  describe('Rule: Minimum planned time based on used time (rounded up to 30 min)', () => {
    it('returns 0 when no time has been used', () => {
      assert.equal(calculateMinimumPlannedSeconds(0), 0);
      assert.equal(calculateMinimumPlannedSeconds(-100), 0);
    });

    it('rounds up partial 30m intervals to the next 30m', () => {
      assert.equal(calculateMinimumPlannedSeconds(1), 1800); // 1s -> 30m
      assert.equal(calculateMinimumPlannedSeconds(900), 1800); // 15m -> 30m
      assert.equal(calculateMinimumPlannedSeconds(1800), 1800); // 30m -> 30m
      assert.equal(calculateMinimumPlannedSeconds(1801), 3600); // 30m 1s -> 1h
      assert.equal(calculateMinimumPlannedSeconds(3600), 3600); // 1h -> 1h
      assert.equal(calculateMinimumPlannedSeconds(7200), 7200); // 2h -> 2h
      assert.equal(calculateMinimumPlannedSeconds(10800), 10800); // 3h -> 3h
      assert.equal(calculateMinimumPlannedSeconds(10801), 12600); // 3h 1s -> 3h 30m
    });

    it('formats duration strings cleanly and friendly', () => {
      assert.equal(formatDurationFriendly(10800), '3h');
      assert.equal(formatDurationFriendly(5400), '1h 30m');
      assert.equal(formatDurationFriendly(1800), '30m');
      assert.equal(formatDurationFriendly(1200), '20m');
      assert.equal(formatDurationFriendly(0), '0m');
    });

    it('never creates instant overtime when planned is at or above minimum planned seconds', () => {
      const usedSeconds = 5400; // 1.5h used
      const minPlanned = calculateMinimumPlannedSeconds(usedSeconds); // 5400 (1.5h)
      const oldPlanned = 7200; // was 2h planned
      const currentRemaining = oldPlanned - usedSeconds; // 1800s (30m left)

      // User sets planned to exactly the minimum (1.5h)
      const newRemaining = calculatePlannedSecondsChange(
        currentRemaining,
        oldPlanned,
        minPlanned,
      );
      assert.equal(newRemaining, 0); // 0 remaining, NOT negative (no overtime)
    });
  });
});
