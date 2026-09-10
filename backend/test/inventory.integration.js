// Run explicitly with: node test/inventory.integration.js
// Uses the configured database and removes only the temporary test records.
const assert = require('node:assert/strict');
const { initDb } = require('../src/database/db');
const { setDoseTaken, updateReminder } = require('../src/controllers/reminderController');

async function main() {
  const db = await initDb();
  let userId;
  try {
    userId = (await db.query("INSERT INTO users (name) VALUES ('Inventory integration test') RETURNING id")).rows[0].id;
    const id = (await db.query(
      `INSERT INTO reminders (user_id, medicine_name, pill_count, initial_pill_count, timings, days)
       VALUES ($1, 'Test stock', 4, 4, '["09:00"]', '["Thu"]') RETURNING id`, [userId]
    )).rows[0].id;
    async function call(handler, body, owner = userId) {
      let status = 200;
      let data;
      await handler({ params: { id }, user: { userId: owner }, body }, {
        status(code) { status = code; return this; },
        json(value) { data = value; },
      });
      return { status, data };
    }
    const dose = (date, taken = true) => ({ date, time: '09:00', taken });
    assert.equal((await call(setDoseTaken, dose('2026-09-01'), -1)).status, 404);
    const concurrent = await Promise.all([
      call(setDoseTaken, dose('2026-09-01')),
      call(setDoseTaken, dose('2026-09-01')),
    ]);
    for (const result of concurrent) {
      assert.equal(result.status, 200);
      assert.equal(result.data.reminder.pill_count, 3);
      assert.equal(result.data.notify_low_stock, false);
    }
    await call(setDoseTaken, dose('2026-09-02'));
    const threshold = await call(setDoseTaken, dose('2026-09-03'));
    assert.equal(threshold.data.reminder.pill_count, 1);
    assert.equal(threshold.data.notify_low_stock, true);
    await call(setDoseTaken, dose('2026-09-03', false));
    assert.equal((await call(setDoseTaken, dose('2026-09-03'))).data.notify_low_stock, false);
    await call(setDoseTaken, dose('2026-09-04'));
    assert.equal((await call(setDoseTaken, dose('2026-09-05'))).status, 409);
    const refill = await call(updateReminder, {
      medicine_name: 'Test stock', pill_count: 4, timings: ['09:00'], days: ['Thu'],
    });
    assert.equal(refill.data.reminder.initial_pill_count, 4);
    assert.equal(refill.data.reminder.low_stock_notified, false);
    console.log('PASS: PostgreSQL ownership, concurrent retries, threshold, undo, empty stock and refill');
  } finally {
    if (userId) {
      await db.query('DELETE FROM reminders WHERE user_id = $1', [userId]);
      await db.query('DELETE FROM users WHERE id = $1', [userId]);
    }
    await db.end();
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
