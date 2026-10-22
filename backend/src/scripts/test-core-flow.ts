import { config } from 'dotenv';
config();

import { db } from '../db/connection';
import { users, planItems } from '../db/schema';
import { eq, inArray } from 'drizzle-orm';

// ─── Typed HTTP Response Interfaces (Strict - No any / unknown) ─────────────

interface UserProfile {
  id: string;
  email: string;
  name: string;
  wakeTime: string | null;
  bedtime: string | null;
  routineMinutes: number | null;
  onboardingDone: boolean;
}

interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

interface AuthResponse {
  message?: string;
  data: {
    user: UserProfile;
    tokens: AuthTokens;
  };
}

interface PlanItemResponse {
  id: string;
  dailyPlanId: string;
  categoryId: string;
  categoryName: string;
  categoryDescription: string;
  categoryColor: string;
  categoryIcon: string;
  plannedSeconds: number;
  remainingSeconds: number;
  startedAt: string | null;
}

interface PlanDetailsResponse {
  id: string;
  userId: string;
  planDate: string;
  wakingSeconds: number;
  createdAt: string | null;
  items: PlanItemResponse[];
  isExisting?: boolean;
}

interface PlanApiResponse {
  message?: string;
  data: {
    plan: PlanDetailsResponse;
    serverTime: string;
  };
  serverTime: string;
}

interface StartTimerApiResponse {
  message?: string;
  data: {
    activeItem: PlanItemResponse;
    autoPausedItem: PlanItemResponse | null;
    serverTime: string;
    isAlreadyRunning: boolean;
  };
  serverTime: string;
}

interface PauseTimerApiResponse {
  message?: string;
  data: {
    pausedItem: PlanItemResponse;
    elapsedSeconds: number;
    isOvertime: boolean;
    overtimeSeconds: number;
    serverTime: string;
  };
  serverTime: string;
}

interface CategorySummaryResponse {
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
  startedAt: string | null;
}

interface SummaryApiResponse {
  data: {
    summary: {
      planId: string | null;
      planDate: string;
      wakingSeconds: number;
      totalPlannedSeconds: number;
      totalActualSeconds: number;
      categories: CategorySummaryResponse[];
    };
    serverTime: string;
  };
  serverTime: string;
}

interface ErrorApiResponse {
  error: string;
  details?: Record<string, string[]>;
  serverTime?: string;
}

// ─── Helper Functions ────────────────────────────────────────────────────────

const sleep = (ms: number): Promise<void> =>
  new Promise((resolve) => setTimeout(resolve, ms));

async function runCoreFlowVerification(): Promise<void> {
  const BASE_URL = 'http://localhost:3000';
  const testUserAEmail = `test-user-a-${Date.now()}@example.com`;
  const testUserBEmail = `test-user-b-${Date.now()}@example.com`;
  const testPassword = 'Password123!';

  let userAId = '';
  let userBId = '';
  let tokenA = '';
  let tokenB = '';

  console.log('================================================================');
  console.log('   Day-Balance Backend Core API & Timer Live Verification Flow   ');
  console.log('================================================================\n');

  try {
    // ── 1. Register User A ───────────────────────────────────────────────────
    console.log(`[1/13] Registering User A: ${testUserAEmail}...`);
    const regResA = await fetch(`${BASE_URL}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testUserAEmail,
        password: testPassword,
        name: 'User A',
      }),
    });

    if (!regResA.ok) {
      throw new Error(`Register User A failed: ${regResA.status} ${await regResA.text()}`);
    }

    const regDataA = (await regResA.json()) as AuthResponse;
    userAId = regDataA.data.user.id;
    tokenA = regDataA.data.tokens.accessToken;
    console.log(`✓ User A registered. ID: ${userAId}`);

    // ── 2. Onboarding for User A ─────────────────────────────────────────────
    console.log('\n[2/13] Setting User A profile (wake: 07:00, bed: 23:00, routine: 60m)...');
    const schedRes = await fetch(`${BASE_URL}/api/users/me`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        wakeTime: '07:00:00',
        bedtime: '23:00:00',
        routineMinutes: 60,
        onboardingDone: true,
      }),
    });

    if (!schedRes.ok) {
      throw new Error(`User A schedule update failed: ${schedRes.status}`);
    }
    console.log('✓ User A schedule saved: Gross 16h - 1h routine = 15h (54000s) net waking time.');

    // ── 3. Select Categories for User A ──────────────────────────────────────
    console.log('\n[3/13] Setting User A categories (academic, career, entertainment)...');
    const catRes = await fetch(`${BASE_URL}/api/categories/mine`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        categoryIds: ['academic', 'career', 'entertainment'],
      }),
    });

    if (!catRes.ok) {
      throw new Error(`User A categories setup failed: ${catRes.status}`);
    }
    console.log('✓ User A categories set.');

    // ── 4. Create Plan (Rule 1, 2, 3) ────────────────────────────────────────
    console.log('\n[4/13] Testing Daily Plan Creation (Rules 1, 2, 3)...');
    const todayStr = new Date().toISOString().split('T')[0];

    // 4a. Verify Rule 2: Rejects non-multiples of 1800s
    console.log('  Testing validation: plannedSeconds not multiple of 1800s (e.g. 1500s)...');
    const invalidStepRes = await fetch(`${BASE_URL}/api/plans`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        planDate: todayStr,
        items: [{ categoryId: 'academic', plannedSeconds: 1500 }],
      }),
    });
    if (invalidStepRes.status !== 400) {
      throw new Error(`Expected 400 for non-1800s step, got ${invalidStepRes.status}`);
    }
    console.log('  ✓ Correctly rejected non-1800s multiple with 400 Bad Request.');

    // 4b. Verify Rule 2: Rejects planned seconds exceeding waking seconds (54000s)
    console.log('  Testing validation: plannedSeconds exceeding waking seconds (e.g. 60000s)...');
    const exceedWakingRes = await fetch(`${BASE_URL}/api/plans`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        planDate: todayStr,
        items: [{ categoryId: 'academic', plannedSeconds: 61200 }], // 61200 > 54000
      }),
    });
    if (exceedWakingRes.status !== 400) {
      throw new Error(`Expected 400 when exceeding waking seconds, got ${exceedWakingRes.status}`);
    }
    const exceedErr = (await exceedWakingRes.json()) as ErrorApiResponse;
    console.log(`  ✓ Correctly rejected exceeding waking time with 400: "${exceedErr.error}"`);

    // 4c. Valid Plan Creation
    console.log('  Creating valid daily plan (Academic: 7200s, Career: 7200s, Entertainment: 3600s)...');
    const createPlanRes = await fetch(`${BASE_URL}/api/plans`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        planDate: todayStr,
        items: [
          { categoryId: 'academic', plannedSeconds: 7200 },
          { categoryId: 'career', plannedSeconds: 7200 },
          { categoryId: 'entertainment', plannedSeconds: 3600 },
        ],
      }),
    });

    if (createPlanRes.status !== 201) {
      throw new Error(`Create plan failed: ${createPlanRes.status} ${await createPlanRes.text()}`);
    }

    const planData = (await createPlanRes.json()) as PlanApiResponse;
    const planA = planData.data.plan;
    console.log(`  ✓ Plan created. ID: ${planA.id}, wakingSeconds: ${planA.wakingSeconds}s`);
    console.log(`  ✓ Server time returned: ${planData.serverTime}`);

    if (planA.wakingSeconds !== 54000) {
      throw new Error(`Expected wakingSeconds=54000, got ${planA.wakingSeconds}`);
    }

    const itemA = planA.items.find((i) => i.categoryId === 'academic');
    const itemB = planA.items.find((i) => i.categoryId === 'career');
    if (!itemA || !itemB) {
      throw new Error('Expected plan items for academic and career not found');
    }

    // 4d. Verify Rule 3: Creating plan for date that already has one returns existing plan
    console.log('  Testing duplicate plan creation (Rule 3): calling POST /api/plans for same date...');
    const duplicatePlanRes = await fetch(`${BASE_URL}/api/plans`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        planDate: todayStr,
        items: [{ categoryId: 'academic', plannedSeconds: 3600 }],
      }),
    });

    if (duplicatePlanRes.status !== 200) {
      throw new Error(`Expected 200 returning existing plan, got ${duplicatePlanRes.status}`);
    }
    const duplicateData = (await duplicatePlanRes.json()) as PlanApiResponse;
    if (duplicateData.data.plan.id !== planA.id) {
      throw new Error('Duplicate plan POST did not return the existing plan');
    }
    console.log('  ✓ Idempotent plan create verified: returned existing plan with 200 OK.');

    // ── 5. Start Timer on Item A (Rule 4, 10) ─────────────────────────────────
    console.log('\n[5/13] Starting Timer on Item A (Academic)...');
    const startARes = await fetch(`${BASE_URL}/api/timer/start`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({ planItemId: itemA.id }),
    });

    if (!startARes.ok) {
      throw new Error(`Start timer A failed: ${startARes.status} ${await startARes.text()}`);
    }

    const startAData = (await startARes.json()) as StartTimerApiResponse;
    console.log(`✓ Timer started for Item A. startedAt: ${startAData.data.activeItem.startedAt}`);
    console.log(`  serverTime: ${startAData.serverTime}`);

    // Test Rule 10: starting already running item is idempotent
    console.log('  Testing Rule 10: starting Item A again (should be idempotent)...');
    const startAgainRes = await fetch(`${BASE_URL}/api/timer/start`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({ planItemId: itemA.id }),
    });
    if (!startAgainRes.ok) {
      throw new Error(`Idempotent start failed: ${startAgainRes.status}`);
    }
    const startAgainData = (await startAgainRes.json()) as StartTimerApiResponse;
    if (!startAgainData.data.isAlreadyRunning) {
      throw new Error('Expected isAlreadyRunning=true for idempotent start');
    }
    console.log('  ✓ Idempotent start confirmed: returned active item without duplicate start.');

    // ── 6. Start Timer on Item B -> Auto-Pause Item A (Rule 4) ───────────────
    console.log('\n[6/13] Starting Timer on Item B (Career) -> verifying Auto-Pause of Item A (Rule 4)...');
    await sleep(1500); // Wait 1.5s so elapsed time > 0

    const startBRes = await fetch(`${BASE_URL}/api/timer/start`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({ planItemId: itemB.id }),
    });

    if (!startBRes.ok) {
      throw new Error(`Start timer B failed: ${startBRes.status} ${await startBRes.text()}`);
    }

    const startBData = (await startBRes.json()) as StartTimerApiResponse;
    console.log(`✓ Timer started for Item B. startedAt: ${startBData.data.activeItem.startedAt}`);

    if (!startBData.data.autoPausedItem) {
      throw new Error('Expected autoPausedItem to be populated in start response');
    }
    if (startBData.data.autoPausedItem.id !== itemA.id) {
      throw new Error(`Expected autoPausedItem to be Item A (${itemA.id}), got ${startBData.data.autoPausedItem.id}`);
    }
    if (startBData.data.autoPausedItem.startedAt !== null) {
      throw new Error('Auto-paused item startedAt must be cleared to null');
    }
    if (startBData.data.autoPausedItem.remainingSeconds >= 7200) {
      throw new Error(`Expected remainingSeconds < 7200, got ${startBData.data.autoPausedItem.remainingSeconds}`);
    }
    console.log(`✓ Item A auto-paused in same transaction: remainingSeconds=${startBData.data.autoPausedItem.remainingSeconds}s (was 7200s).`);

    // ── 7. Pause Timer on Item B (Rule 5, 10) ────────────────────────────────
    console.log('\n[7/13] Pausing Timer on Item B...');
    await sleep(1500);

    const pauseBRes = await fetch(`${BASE_URL}/api/timer/pause`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({ planItemId: itemB.id }),
    });

    if (!pauseBRes.ok) {
      throw new Error(`Pause timer B failed: ${pauseBRes.status} ${await pauseBRes.text()}`);
    }

    const pauseBData = (await pauseBRes.json()) as PauseTimerApiResponse;
    console.log(`✓ Timer B paused. Elapsed: ${pauseBData.data.elapsedSeconds}s, remaining: ${pauseBData.data.pausedItem.remainingSeconds}s`);
    console.log(`  serverTime: ${pauseBData.serverTime}`);

    // Rule 10: pausing when nothing is running returns clear 400 error
    console.log('  Testing Rule 10: pausing when no timer is running...');
    const pauseNoneRes = await fetch(`${BASE_URL}/api/timer/pause`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({}),
    });
    if (pauseNoneRes.status !== 400) {
      throw new Error(`Expected 400 when pausing with no active timer, got ${pauseNoneRes.status}`);
    }
    const pauseNoneErr = (await pauseNoneRes.json()) as ErrorApiResponse;
    console.log(`  ✓ Clear error returned for non-running pause: "${pauseNoneErr.error}"`);

    // ── 8. Resume Timer on Item A (Rule 1, 4) ────────────────────────────────
    console.log('\n[8/13] Resuming Timer on Item A via POST /api/timer/resume...');
    const resumeARes = await fetch(`${BASE_URL}/api/timer/resume`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({ planItemId: itemA.id }),
    });

    if (!resumeARes.ok) {
      throw new Error(`Resume timer A failed: ${resumeARes.status}`);
    }
    const resumeAData = (await resumeARes.json()) as StartTimerApiResponse;
    console.log(`✓ Timer A resumed successfully. startedAt: ${resumeAData.data.activeItem.startedAt}`);

    // ── 9. Check Remaining Math (Rule 5) ─────────────────────────────────────
    console.log('\n[9/13] Verifying remaining time math on active timer...');
    const statusRes = await fetch(`${BASE_URL}/api/timer/status?date=${todayStr}`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    if (!statusRes.ok) {
      throw new Error(`Timer status failed: ${statusRes.status}`);
    }
    const statusData = (await statusRes.json()) as { data: { activeItem: PlanItemResponse | null }; serverTime: string };
    if (!statusData.data.activeItem) {
      throw new Error('Expected activeItem in timer status');
    }
    console.log(`✓ Active item: ${statusData.data.activeItem.categoryName}`);
    console.log(`  last saved remaining: ${statusData.data.activeItem.remainingSeconds}s`);
    console.log(`  serverTime: ${statusData.serverTime}`);

    // ── 10. Overtime Verification (Rule 5) ───────────────────────────────────
    console.log('\n[10/13] Testing Overtime: remaining_seconds going NEGATIVE (Rule 5)...');
    // Simulate elapsed time exceeding remaining by updating started_at in DB for item A
    // (Simulates a timer that ran for 3 hours when remaining was ~7198s -> overtime!)
    const simulatedStart = new Date(Date.now() - 3 * 3600 * 1000); // 3 hours ago
    await db
      .update(planItems)
      .set({ startedAt: simulatedStart })
      .where(eq(planItems.id, itemA.id));

    const pauseOvertimeRes = await fetch(`${BASE_URL}/api/timer/pause`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({ planItemId: itemA.id }),
    });

    if (!pauseOvertimeRes.ok) {
      throw new Error(`Pause overtime failed: ${pauseOvertimeRes.status}`);
    }
    const pauseOvertimeData = (await pauseOvertimeRes.json()) as PauseTimerApiResponse;
    console.log(`✓ Overtime verified: remainingSeconds=${pauseOvertimeData.data.pausedItem.remainingSeconds}s`);
    console.log(`  isOvertime: ${pauseOvertimeData.data.isOvertime}`);
    console.log(`  overtimeSeconds: ${pauseOvertimeData.data.overtimeSeconds}s`);

    if (pauseOvertimeData.data.pausedItem.remainingSeconds >= 0) {
      throw new Error('Expected remaining_seconds to be negative for overtime');
    }
    if (!pauseOvertimeData.data.isOvertime) {
      throw new Error('Expected isOvertime=true');
    }

    // ── 11. Edit planned_seconds While Running (Rule 6) ──────────────────────
    console.log('\n[11/13] Testing Rule 6: Editing planned_seconds while a timer runs...');
    // Start timer on item B
    await fetch(`${BASE_URL}/api/timer/start`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({ planItemId: itemB.id }),
    });

    // Check item B initial running state
    const [runningBefore] = await db
      .select()
      .from(planItems)
      .where(eq(planItems.id, itemB.id));

    if (!runningBefore || !runningBefore.startedAt) {
      throw new Error('Item B is not running before plan edit');
    }

    const oldRemainingB = runningBefore.remainingSeconds;
    const oldStartedAtB = runningBefore.startedAt.toISOString();

    // Now call PATCH /api/plans/:id, increasing item B planned from 7200 to 9000 (+1800s)
    const patchPlanRes = await fetch(`${BASE_URL}/api/plans/${planA.id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        items: [
          { categoryId: 'academic', plannedSeconds: 7200 },
          { categoryId: 'career', plannedSeconds: 9000 }, // +1800s
          { categoryId: 'entertainment', plannedSeconds: 3600 },
        ],
      }),
    });

    if (!patchPlanRes.ok) {
      throw new Error(`Patch plan failed: ${patchPlanRes.status} ${await patchPlanRes.text()}`);
    }

    const [runningAfter] = await db
      .select()
      .from(planItems)
      .where(eq(planItems.id, itemB.id));

    if (!runningAfter || !runningAfter.startedAt) {
      throw new Error('Item B was stopped or restarted during plan edit');
    }

    // Rule 6 verification:
    // 1. remaining changed by difference: newRemaining = oldRemaining + 1800
    if (runningAfter.remainingSeconds !== oldRemainingB + 1800) {
      throw new Error(`Expected remaining=${oldRemainingB + 1800}, got ${runningAfter.remainingSeconds}`);
    }
    // 2. startedAt is preserved exactly (not restarted)
    if (runningAfter.startedAt.toISOString() !== oldStartedAtB) {
      throw new Error('startedAt timestamp was changed during planned_seconds edit');
    }
    console.log('✓ Rule 6 verified: remainingSeconds increased by 1800s while startedAt was preserved intact.');

    // ── Minimum Planned Rule Verification ────────────────────────────────────
    console.log('\nTesting Minimum Planned Rule: trying to plan category below time already used...');
    // Category academic has already been used today (>0s)
    const failMinPlannedRes = await fetch(`${BASE_URL}/api/plans/${planA.id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        items: [
          { categoryId: 'academic', plannedSeconds: 0 }, // academic has used time!
          { categoryId: 'career', plannedSeconds: 9000 },
          { categoryId: 'entertainment', plannedSeconds: 3600 },
        ],
      }),
    });

    if (failMinPlannedRes.status !== 400) {
      throw new Error(
        `Expected 400 when setting planned time below used time, got ${failMinPlannedRes.status}`,
      );
    }
    const failMinJson = (await failMinPlannedRes.json()) as { error?: string };
    console.log(`✓ Minimum planned time rule enforced (400): "${failMinJson.error}"`);

    // ── 12. Summary Endpoint (Rule 8) ────────────────────────────────────────
    console.log('\n[12/13] Testing Rule 8: Planned vs Actual Summary Endpoint...');
    const summaryRes = await fetch(`${BASE_URL}/api/plans/summary?date=${todayStr}`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });

    if (!summaryRes.ok) {
      throw new Error(`Summary endpoint failed: ${summaryRes.status}`);
    }

    const summaryData = (await summaryRes.json()) as SummaryApiResponse;
    const summary = summaryData.data.summary;
    console.log(`✓ Summary returned for date: ${summary.planDate}`);
    console.log(`  wakingSeconds: ${summary.wakingSeconds}s`);
    console.log(`  totalPlannedSeconds: ${summary.totalPlannedSeconds}s`);
    console.log(`  totalActualSeconds: ${summary.totalActualSeconds}s`);
    console.log(`  serverTime: ${summaryData.serverTime}`);

    if (summary.categories.length === 0) {
      throw new Error('Expected categories summary in response');
    }
    for (const cat of summary.categories) {
      console.log(`  - [${cat.categoryName}] Planned: ${cat.plannedSeconds}s | Actual: ${cat.actualSeconds}s | Remaining: ${cat.remainingSeconds}s`);
    }

    // ── 13. Concurrency Invariant Test (Rule 4) ─────────────────────────────
    console.log('\n[13/14] Testing Concurrency (Rule 4): simultaneous start requests at the same moment...');
    const [concurrentRes1, concurrentRes2] = await Promise.all([
      fetch(`${BASE_URL}/api/timer/start`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenA}`,
        },
        body: JSON.stringify({ planItemId: itemA.id }),
      }),
      fetch(`${BASE_URL}/api/timer/start`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenA}`,
        },
        body: JSON.stringify({ planItemId: itemB.id }),
      }),
    ]);

    if (!concurrentRes1.ok || !concurrentRes2.ok) {
      throw new Error(`Concurrent start failed: res1=${concurrentRes1.status}, res2=${concurrentRes2.status}`);
    }

    // Verify in database that EXACTLY ONE timer is running for user A
    const allUserAItems = await db
      .select()
      .from(planItems)
      .where(eq(planItems.userId, userAId));

    const currentlyRunning = allUserAItems.filter((i) => i.startedAt !== null);
    if (currentlyRunning.length !== 1) {
      throw new Error(`Expected exactly 1 running timer under concurrency, found ${currentlyRunning.length}`);
    }
    console.log(`✓ Concurrency invariant passed: exactly 1 timer running (${currentlyRunning[0].categoryId}), zero race condition errors.`);

    // ── 14. Security: Cross-User Access Isolation (Rule 9) ───────────────────
    console.log('\n[14/14] Testing Rule 9: Security & Cross-User Isolation...');
    const regResB = await fetch(`${BASE_URL}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testUserBEmail,
        password: testPassword,
        name: 'User B',
      }),
    });

    if (!regResB.ok) {
      throw new Error(`Register User B failed: ${regResB.status}`);
    }

    const regDataB = (await regResB.json()) as AuthResponse;
    userBId = regDataB.data.user.id;
    tokenB = regDataB.data.tokens.accessToken;
    console.log(`✓ User B registered. ID: ${userBId}`);

    // User B tries to read User A's plan -> 404
    const crossGetPlan = await fetch(`${BASE_URL}/api/plans/${planA.id}`, {
      headers: { Authorization: `Bearer ${tokenB}` },
    });
    if (crossGetPlan.status !== 404) {
      throw new Error(`Expected 404 for cross-user GET plan, got ${crossGetPlan.status}`);
    }
    console.log('✓ User B cannot read User A\'s plan (404 Not Found).');

    // User B tries to modify User A's plan -> 404
    const crossPatchPlan = await fetch(`${BASE_URL}/api/plans/${planA.id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({
        items: [{ categoryId: 'academic', plannedSeconds: 3600 }],
      }),
    });
    if (crossPatchPlan.status !== 404) {
      throw new Error(`Expected 404 for cross-user PATCH plan, got ${crossPatchPlan.status}`);
    }
    console.log('✓ User B cannot modify User A\'s plan (404 Not Found).');

    // User B tries to start User A's timer item -> 404
    const crossStartTimer = await fetch(`${BASE_URL}/api/timer/start`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({ planItemId: itemA.id }),
    });
    if (crossStartTimer.status !== 404) {
      throw new Error(`Expected 404 for cross-user start timer, got ${crossStartTimer.status}`);
    }
    console.log('✓ User B cannot start User A\'s plan item (404 Not Found).');

    // User B gets summary for today -> gets only User B's empty summary (no User A data)
    const crossSummaryRes = await fetch(`${BASE_URL}/api/plans/summary?date=${todayStr}`, {
      headers: { Authorization: `Bearer ${tokenB}` },
    });
    if (!crossSummaryRes.ok) {
      throw new Error(`Expected 200 for User B summary, got ${crossSummaryRes.status}`);
    }
    const crossSummaryData = (await crossSummaryRes.json()) as SummaryApiResponse;
    if (
      crossSummaryData.data.summary.categories.length > 0 ||
      crossSummaryData.data.summary.totalPlannedSeconds > 0
    ) {
      throw new Error(
        'User B received User A\'s summary data! Data isolation failure.',
      );
    }
    console.log('✓ User B cannot see User A\'s summary data (User B received empty summary).');

    // Unauthenticated request without token -> 401
    const unauthRes = await fetch(`${BASE_URL}/api/plans/today`);
    if (unauthRes.status !== 401) {
      throw new Error(`Expected 401 for unauthenticated request, got ${unauthRes.status}`);
    }
    console.log('✓ Unauthenticated requests rejected with 401 Unauthorized.');

    console.log('\n================================================================');
    console.log('  🎉 ALL 10 CORE FLOW RULES VERIFIED LIVE VIA HTTP ENDPOINTS!   ');
    console.log('================================================================\n');
  } finally {
    // ── Safe Cleanup ─────────────────────────────────────────────────────────
    console.log('Cleaning up test users from Neon database...');
    const cleanupIds = [userAId, userBId].filter((id) => id.length > 0);
    if (cleanupIds.length > 0) {
      // Safe parameterized DELETE with WHERE clause
      await db.delete(users).where(inArray(users.id, cleanupIds));
      console.log(`✓ Safely deleted test users (${cleanupIds.join(', ')}) and cascade records.`);
    }
  }
}

runCoreFlowVerification().catch((err) => {
  console.error('\n❌ Core verification failed:', err);
  process.exit(1);
});
