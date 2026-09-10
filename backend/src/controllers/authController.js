const { getDb } = require('../database/db');
const { issueToken } = require('../services/tokenService');

async function signup(req, res) {
  try {
    const { name, phoneNumber, password } = req.body;
    if (typeof name !== 'string' || !name.trim() || typeof phoneNumber !== 'string' || !phoneNumber.trim() || typeof password !== 'string' || !password) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const db = getDb();
    
    // Check if user exists
    const checkUser = await db.query('SELECT * FROM users WHERE phone_number = $1', [phoneNumber]);
    if (checkUser.rows.length > 0) {
      return res.status(409).json({ error: 'Phone number already registered' });
    }

    // Insert user (PlainText password for MVP)
    const result = await db.query(
      'INSERT INTO users (name, phone_number, password) VALUES ($1, $2, $3) RETURNING id, name, phone_number',
      [name, phoneNumber, password]
    );

    const user = result.rows[0];

    // Generate JWT token
    const token = issueToken(user);

    res.status(201).json({
      message: 'User created',
      token,
      user
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ error: 'Failed to sign up' });
  }
}

async function login(req, res) {
  try {
    const { phoneNumber, password } = req.body;
    if (typeof phoneNumber !== 'string' || !phoneNumber.trim() || typeof password !== 'string' || !password) {
      return res.status(400).json({ error: 'Missing phone number or password' });
    }

    const db = getDb();
    
    const result = await db.query('SELECT id, name, phone_number, password FROM users WHERE phone_number = $1', [phoneNumber]);
    
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid phone number or password' });
    }

    const user = result.rows[0];
    
    if (user.password !== password) {
      return res.status(401).json({ error: 'Invalid phone number or password' });
    }

    // Don't send password back
    delete user.password;

    // Generate JWT token
    const token = issueToken(user);

    res.json({
      message: 'Login successful',
      token,
      user
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Failed to log in' });
  }
}

module.exports = { signup, login };
