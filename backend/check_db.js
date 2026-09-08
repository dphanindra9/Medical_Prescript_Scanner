const { initDb, getDb } = require('./src/database/db');

async function check() {
  const pool = await initDb();
  try {
    const res = await pool.query('SELECT * FROM users');
    console.log("USERS:", res.rows);
  } catch (err) {
    console.error("ERROR:", err.message);
  } finally {
    process.exit(0);
  }
}

check();
