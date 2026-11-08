import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';

const base = 'http://localhost:3000/api';
const sessions: string[] = [];
async function request(path: string, method = 'GET', token?: string, body?: unknown) {
  const response = await fetch(base + path, {
    method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const data = response.status === 204 ? {} : await response.json() as any;
  return { status: response.status, data };
}

async function main() {
  try {
    for (let i = 0; i < 2; i++) {
      const registered = await request('/auth/register', 'POST', undefined, {
        email: `custom-${randomUUID()}@example.com`, password: 'TestOnly!123456', displayName: 'Category test',
      });
      assert.equal(registered.status, 201);
      sessions.push(registered.data.data.tokens.accessToken);
    }
    const [owner, other] = sessions;
    const created = await request('/categories/custom', 'POST', owner,
      { name: 'Guitar practice', description: 'A private daily priority', color: '#A9CEC6' });
    assert.equal(created.status, 201);
    const id = created.data.data.category.id;
    assert.equal((await request('/categories/custom', 'POST', owner, { name: 'guitar practice' })).status, 409);
    const list = (await request('/categories/available', 'GET', owner)).data.data.categories;
    assert.ok(list.some((c: any) => c.id === id));
    for (const result of [await request('/categories'), await request('/categories/available', 'GET', other)]) {
      assert.ok(!result.data.data.categories.some((c: any) => c.id === id));
    }
    assert.equal((await request('/categories/mine', 'PUT', other, { categoryIds: [id] })).status, 400);
    const planDate = new Date().toISOString().slice(0, 10);
    assert.equal((await request('/plans', 'POST', other,
      { planDate, items: [{ categoryId: id, plannedSeconds: 1800 }] })).status, 400);
    const plan = await request('/plans', 'POST', owner,
      { planDate, items: [{ categoryId: id, plannedSeconds: 1800 }] });
    assert.equal(plan.status, 201);
    assert.equal(plan.data.data.plan.items[0].categoryName, 'Guitar practice');
    console.log('Custom category persistence, duplicate validation, plan integration and user isolation passed.');
  } finally {
    const cleanup = await Promise.allSettled(sessions.map(async token => {
      const deleted = await request('/auth/account', 'DELETE', token);
      assert.ok([200, 204].includes(deleted.status), 'Test account cleanup failed');
    }));
    assert.ok(cleanup.every(result => result.status === 'fulfilled'), 'Test account cleanup failed');
  }
}
main().catch(error => { console.error(error instanceof Error ? error.message : 'Custom category tests failed'); process.exitCode = 1; });
