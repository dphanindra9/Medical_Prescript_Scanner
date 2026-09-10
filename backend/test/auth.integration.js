// Explicit database integration test; removes its own temporary user afterward.
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const { initDb } = require('../src/database/db');
const { login } = require('../src/controllers/authController');
const { authenticateToken } = require('../src/middleware/authMiddleware');
const { issueToken, verifyToken, SESSION_SECONDS } = require('../src/services/tokenService');

function response() {
  return {
    code: 200, headers: {},
    status(code) { this.code = code; return this; },
    json(data) { this.data = data; },
    setHeader(key, value) { this.headers[key] = value; },
  };
}

async function main() {
  const db = await initDb();
  let user;
  try {
    user = (await db.query(
      'INSERT INTO users (name, phone_number, password) VALUES ($1, $2, $3) RETURNING *',
      ['Session integration test', `session-test-${Date.now()}`, 'test-only-password']
    )).rows[0];
    const invalid = response();
    await login({ body: { phoneNumber: user.phone_number, password: 'wrong' } }, invalid);
    assert.equal(invalid.code, 401);
    assert.equal(invalid.data.token, undefined);
    const valid = response();
    await login({ body: { phoneNumber: user.phone_number, password: user.password } }, valid);
    assert.equal(valid.code, 200);
    assert.equal(valid.data.user.password, undefined);
    const claims = verifyToken(valid.data.token);
    assert.equal(claims.exp - claims.iat, 20 * 24 * 60 * 60);

    const now = Math.floor(Date.now() / 1000);
    const oldToken = jwt.sign({ userId: user.id, iat: now - SESSION_SECONDS + 60 },
      process.env.JWT_SECRET, { expiresIn: SESSION_SECONDS });
    const active = response();
    let authorized = false;
    await authenticateToken({ headers: { authorization: `Bearer ${oldToken}` } }, active,
      () => { authorized = true; });
    assert.equal(authorized, true);
    assert.ok(verifyToken(active.headers['X-Session-Token']).exp >= now + SESSION_SECONDS);

    for (const token of [
      jwt.sign({ userId: user.id, iat: now - SESSION_SECONDS }, process.env.JWT_SECRET,
        { expiresIn: SESSION_SECONDS }),
      `${valid.data.token}tampered`,
      issueToken({ id: -1 }),
    ]) {
      const rejected = response();
      await authenticateToken({ headers: { authorization: `Bearer ${token}` } }, rejected,
        () => assert.fail('Invalid session accepted'));
      assert.equal(rejected.code, 401);
    }
    console.log('PASS: credentials, 20-day expiry boundary, rolling renewal, tampering and missing user');
  } finally {
    if (user) await db.query('DELETE FROM users WHERE id = $1', [user.id]);
    await db.end();
  }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
