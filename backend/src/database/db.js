const { Pool } = require('pg');
require('dotenv').config();

let pool = null;

async function initDb() {
  pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
  });

  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name TEXT,
        phone_number TEXT UNIQUE,
        password TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS prescriptions (
        id SERIAL PRIMARY KEY,
        patient_name TEXT,
        doctor_name TEXT,
        prescription_date TEXT,
        instructions TEXT,
        raw_text TEXT,
        image_path TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS medicines (
        id SERIAL PRIMARY KEY,
        prescription_id INTEGER REFERENCES prescriptions(id) ON DELETE CASCADE,
        name TEXT,
        dosage TEXT,
        frequency TEXT,
        duration TEXT
      );

      ALTER TABLE prescriptions ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

      CREATE TABLE IF NOT EXISTS reminders (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        medicine_name TEXT,
        pill_count INTEGER,
        timings JSONB,
        days JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      ALTER TABLE reminders ADD COLUMN IF NOT EXISTS initial_pill_count INTEGER;
      ALTER TABLE reminders ADD COLUMN IF NOT EXISTS low_stock_notified BOOLEAN NOT NULL DEFAULT FALSE;
      ALTER TABLE reminders ADD COLUMN IF NOT EXISTS taken_doses JSONB NOT NULL DEFAULT '{}';
      UPDATE reminders SET initial_pill_count = COALESCE(pill_count, 0)
        WHERE initial_pill_count IS NULL;
    `);
    console.log('PostgreSQL Database initialized and connected.');
  } finally {
    client.release();
  }

  return pool;
}

function getDb() {
  if (!pool) {
    throw new Error('Database not initialized');
  }
  return pool;
}

module.exports = { initDb, getDb };
