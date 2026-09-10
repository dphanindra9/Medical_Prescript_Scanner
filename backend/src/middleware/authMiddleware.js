const { verifyToken, issueToken } = require('../services/tokenService');
const { getDb } = require('../database/db');

async function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = typeof authHeader === 'string' && /^Bearer \S+$/i.test(authHeader)
    ? authHeader.split(' ')[1] : null;

  if (!token) {
    return res.status(401).json({ error: 'Access denied. No token provided.' });
  }

  let decoded;
  try {
    decoded = verifyToken(token);
    if (!Number.isInteger(decoded.userId)) throw new Error('Invalid user');
  } catch (_) {
    return res.status(401).json({ error: 'Session expired. Please log in again.' });
  }
  try {
    const result = await getDb().query(
      'SELECT id, name, phone_number FROM users WHERE id = $1', [decoded.userId]
    );
    if (!result.rows.length) return res.status(401).json({ error: 'Please log in again.' });
    req.user = { userId: decoded.userId };
    req.authUser = result.rows[0];
    // Every authenticated foreground request extends the inactivity window.
    res.setHeader('X-Session-Token', issueToken(req.authUser));
    res.setHeader('Cache-Control', 'no-store');
    return next();
  } catch (_) {
    return res.status(503).json({ error: 'Unable to verify session. Please try again.' });
  }
}

module.exports = { authenticateToken };
