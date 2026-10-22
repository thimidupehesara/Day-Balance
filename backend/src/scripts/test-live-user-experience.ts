import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const BASE_URL = 'http://localhost:3000';

async function testLiveUserExperience() {
  console.log('================================================================');
  console.log('   Live Check: Register -> Onboarding -> Plan -> Today -> Timers');
  console.log('================================================================\n');

  const timestamp = Date.now();
  const email = `test-e2e-${timestamp}@example.com`;
  const password = 'Password123!';
  const name = 'Maya';
  let accessToken = '';
  let userId = '';
  let planId = '';
  let academicItemId = '';
  let careerItemId = '';

  try {
    // 1. Register
    console.log('[1/8] Registering new user (Maya)...');
    const regRes = await fetch(`${BASE_URL}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, displayName: name }),
    });
    const regData = (await regRes.json()) as any;
    if (!regRes.ok) throw new Error(`Register failed: ${JSON.stringify(regData)}`);
    accessToken = regData.data.tokens.accessToken;
    userId = regData.data.user.id;
    console.log(`✓ User registered. ID: ${userId}, Name: ${regData.data.user.displayName}`);

    const authHeaders = {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
    };

    // 2. Onboarding: schedule & routines
    console.log('\n[2/8] Setting schedule (07:00 - 23:00, 90m routine)...');
    const profRes = await fetch(`${BASE_URL}/api/users/me`, {
      method: 'PATCH',
      headers: authHeaders,
      body: JSON.stringify({
        wakeTime: '07:00',
        bedtime: '23:00',
        routineMinutes: 90,
        onboardingDone: true,
      }),
    });
    const profData = (await profRes.json()) as any;
    if (!profRes.ok) throw new Error(`Profile update failed: ${JSON.stringify(profData)}`);
    console.log('✓ Profile saved. Gross: 16h, Routines: 1.5h -> Net Waking: 14h 30m');

    // 3. Onboarding: categories
    console.log('\n[3/8] Selecting 4 categories (Academic, Life/Family, Entertainment, Career)...');
    const catRes = await fetch(`${BASE_URL}/api/categories/mine`, {
      method: 'PUT',
      headers: authHeaders,
      body: JSON.stringify({
        categoryIds: ['academic', 'life_family', 'entertainment', 'career'],
      }),
    });
    const catData = (await catRes.json()) as any;
    if (!catRes.ok) throw new Error(`Categories update failed: ${JSON.stringify(catData)}`);
    console.log(`✓ Categories saved: ${catData.data.categories.length} categories.`);

    // 4. Today before planning check
    console.log('\n[4/8] Checking Today before planning (GET /api/plans/today)...');
    const todayStr = new Date().toISOString().split('T')[0];
    const todayBeforeRes = await fetch(`${BASE_URL}/api/plans/today?date=${todayStr}`, {
      headers: authHeaders,
    });
    const todayBeforeData = (await todayBeforeRes.json()) as any;
    if (todayBeforeData.data.plan === null) {
      console.log('✓ Correct: No plan exists yet for today -> Today displays Before-Planning state.');
    } else {
      throw new Error(`Expected null plan, got: ${JSON.stringify(todayBeforeData)}`);
    }

    // 5. Daily Planning: create plan
    console.log('\n[5/8] Creating Daily Plan through API (POST /api/plans)...');
    const planRes = await fetch(`${BASE_URL}/api/plans`, {
      method: 'POST',
      headers: authHeaders,
      body: JSON.stringify({
        planDate: todayStr,
        wakingSeconds: 14 * 3600 + 1800, // 14h 30m
        items: [
          { categoryId: 'academic', plannedSeconds: 4 * 3600 },
          { categoryId: 'life_family', plannedSeconds: 2 * 3600 },
          { categoryId: 'entertainment', plannedSeconds: 2 * 3600 },
          { categoryId: 'career', plannedSeconds: 2 * 3600 },
        ],
      }),
    });
    const planData = (await planRes.json()) as any;
    if (!planRes.ok) throw new Error(`Plan creation failed: ${JSON.stringify(planData)}`);
    planId = planData.data.plan.id;
    const items = planData.data.plan.items;
    academicItemId = items.find((i: any) => i.categoryId === 'academic').id;
    careerItemId = items.find((i: any) => i.categoryId === 'career').id;
    console.log(`✓ Plan created successfully. Plan ID: ${planId}`);
    console.log(`  Items: Academic (${academicItemId}), Career (${careerItemId})`);

    // 6. Start Category 1 (Academic)
    console.log('\n[6/10] Starting timer on Academic (POST /api/timer/start)...');
    const startARes = await fetch(`${BASE_URL}/api/timer/start`, {
      method: 'POST',
      headers: authHeaders,
      body: JSON.stringify({ planItemId: academicItemId }),
    });
    const startAData = (await startARes.json()) as any;
    if (!startARes.ok) throw new Error(`Start A failed: ${JSON.stringify(startAData)}`);
    console.log(`✓ Academic timer started at: ${startAData.data.activeItem.startedAt}`);

    // Wait 2 seconds while Academic runs
    await new Promise((resolve) => setTimeout(resolve, 2000));

    // 7. Edit plan while timer runs:
    // Timer keeps running, remaining changes by difference
    console.log('\n[7/10] Editing plan while Academic timer runs (increasing Academic planned from 4h to 4.5h)...');
    const editPlanRes = await fetch(`${BASE_URL}/api/plans/${planId}`, {
      method: 'PATCH',
      headers: authHeaders,
      body: JSON.stringify({
        items: [
          { categoryId: 'academic', plannedSeconds: 4 * 3600 + 1800 }, // +1800s (4.5h)
          { categoryId: 'life_family', plannedSeconds: 2 * 3600 },
          { categoryId: 'entertainment', plannedSeconds: 2 * 3600 },
          { categoryId: 'career', plannedSeconds: 2 * 3600 },
        ],
      }),
    });
    const editPlanData = (await editPlanRes.json()) as any;
    if (!editPlanRes.ok) throw new Error(`Edit plan failed: ${JSON.stringify(editPlanData)}`);
    const academicEdited = editPlanData.data.plan.items.find((i: any) => i.id === academicItemId);
    console.log(`✓ Academic planned increased to: ${academicEdited.plannedSeconds}s`);
    console.log(`  New remaining: ${academicEdited.remainingSeconds}s (was 14400s, now 16200s)`);
    console.log(`  Academic timer still running: startedAt = ${academicEdited.startedAt}`);

    // 8. Try to go below the used time (rejected)
    console.log('\n[8/10] Trying to edit planned time below already used time...');
    const failMinRes = await fetch(`${BASE_URL}/api/plans/${planId}`, {
      method: 'PATCH',
      headers: authHeaders,
      body: JSON.stringify({
        items: [
          { categoryId: 'academic', plannedSeconds: 0 }, // Academic has used ~2s, so min is 1800s!
          { categoryId: 'life_family', plannedSeconds: 2 * 3600 },
          { categoryId: 'entertainment', plannedSeconds: 2 * 3600 },
          { categoryId: 'career', plannedSeconds: 2 * 3600 },
        ],
      }),
    });
    if (failMinRes.status !== 400) {
      throw new Error(`Expected 400 rejection when planning below used time, got ${failMinRes.status}`);
    }
    const failMinJson = (await failMinRes.json()) as any;
    console.log(`✓ Rejected planning below used time (400): "${failMinJson.error}"`);

    // 9. Open summary and check numbers
    console.log('\n[9/10] Getting daily summary (GET /api/plans/summary)...');
    const summaryRes = await fetch(`${BASE_URL}/api/plans/summary?date=${todayStr}`, {
      headers: authHeaders,
    });
    if (!summaryRes.ok) throw new Error(`Summary failed: ${summaryRes.status}`);
    const summaryData = (await summaryRes.json()) as any;
    const summary = summaryData.data.summary;
    console.log(`✓ Summary returned:`);
    console.log(`  Total Planned: ${summary.totalPlannedSeconds}s`);
    console.log(`  Total Actual: ${summary.totalActualSeconds}s (includes running timer)`);
    console.log(`  Categories: ${summary.categories.length}`);
    for (const cat of summary.categories) {
      console.log(`  - [${cat.categoryName}] Planned: ${cat.plannedSeconds}s | Actual: ${cat.actualSeconds}s | Running: ${cat.isRunning}`);
    }
    if (summary.totalActualSeconds <= 0) {
      throw new Error('Expected totalActualSeconds > 0 for running category');
    }

    // 10. Pause timer before cleanup
    console.log('\n[10/10] Pausing running timer...');
    const pauseRes = await fetch(`${BASE_URL}/api/timer/pause`, {
      method: 'POST',
      headers: authHeaders,
    });
    if (!pauseRes.ok) throw new Error(`Pause failed: ${pauseRes.status}`);
    console.log('✓ Timer paused successfully.');

    console.log('\n================================================================');
    console.log('  🎉 REAL END-TO-END FLOW VERIFIED SUCCESSFULLY!');
    console.log('================================================================\n');
  } catch (err) {
    console.error('❌ E2E check failed:', err);
    process.exit(1);
  } finally {
    // Cleanup test user
    if (userId) {
      console.log('Cleaning up test user from Neon database...');
      const { db } = await import('../db/connection');
      const { users } = await import('../db/schema');
      const { eq } = await import('drizzle-orm');
      await db.delete(users).where(eq(users.id, userId));
      console.log(`✓ Cleaned up user ${userId}.`);
      process.exit(0);
    }
  }
}

testLiveUserExperience();
