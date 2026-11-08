import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { createCategorySchema } from '../modules/categories/categories.validation';
import { canUseCategory, customCategoryPrefix } from '../modules/categories/category-access';

describe('Private custom categories (offline)', () => {
  it('accepts and trims names and descriptions', () => {
    const result = createCategorySchema.parse({ name: '  Guitar  ', description: ' Practice daily ' });
    assert.equal(result.name, 'Guitar');
    assert.equal(result.description, 'Practice daily');
    assert.equal(result.color, '#A9CEC6');
  });
  it('rejects empty or oversized names and arbitrary fields or colors', () => {
    for (const input of [{name:' '}, {name:'x'.repeat(41)}, {name:'Guitar', color:'red'},
      {name:'Guitar', id:'academic'}, {name:'Guitar', userId:'another-user'},
      {name:'Guitar', description:'x'.repeat(101)}]) {
      assert.equal(createCategorySchema.safeParse(input).success, false);
    }
  });
  it('allows system categories and only the exact owner namespace', () => {
    assert.equal(canUseCategory('user-a', 'academic'), true);
    assert.equal(canUseCategory('user-a', customCategoryPrefix('user-a')+'123'), true);
    assert.equal(canUseCategory('user-b', customCategoryPrefix('user-a')+'123'), false);
    assert.equal(canUseCategory('user', customCategoryPrefix('user-a')+'123'), false);
    assert.equal(canUseCategory('user-a', 'custom:user-a-forged:123'), false);
  });
});
