const test = require('node:test');
const assert = require('node:assert/strict');
const { applyDose } = require('../src/services/inventoryService');

const stock = (count = 20) => ({
  pill_count: count, initial_pill_count: count, low_stock_notified: false, taken_doses: {},
});

test('taking, retrying and undoing a dose maintain the inventory', () => {
  const original = stock();
  const taken = { ...original, ...applyDose(original, '2026-09-10_09:00', true) };
  assert.equal(taken.pill_count, 19);
  assert.equal(applyDose(taken, '2026-09-10_09:00', true).pill_count, 19);
  const undone = { ...taken, ...applyDose(taken, '2026-09-10_09:00', false) };
  assert.equal(undone.pill_count, 20);
  assert.equal(applyDose(undone, '2026-09-10_09:00', false).pill_count, 20);
});

test('alert occurs only once at a quarter, including after undo and recheck', () => {
  let reminder = stock();
  let alerts = 0;
  for (let i = 0; i < 20; i++) {
    const change = applyDose(reminder, `dose-${i}`, true);
    if (change.notify) {
      alerts++;
      assert.equal(change.pill_count, 5);
    }
    reminder = { ...reminder, ...change };
  }
  assert.equal(alerts, 1);
  reminder = { ...reminder, ...applyDose(reminder, 'dose-19', false) };
  assert.equal(applyDose(reminder, 'dose-19', true).notify, false);
});

test('non-divisible quantities notify when crossing below a quarter', () => {
  const reminder = { ...stock(10), pill_count: 3 };
  const change = applyDose(reminder, 'dose', true);
  assert.equal(change.pill_count, 2);
  assert.equal(change.notify, true);
});

test('empty inventory rejects taking a tablet without modifying state', () => {
  const reminder = stock(0);
  assert.throws(() => applyDose(reminder, 'dose', true), { status: 409 });
  assert.deepEqual(reminder.taken_doses, {});
  assert.equal(reminder.pill_count, 0);
});
