const jwt = require('jsonwebtoken');

const SESSION_SECONDS = 20 * 24 * 60 * 60;

function secret() {
  if (!process.env.JWT_SECRET) throw new Error('JWT_SECRET must be configured');
  return process.env.JWT_SECRET;
}

function issueToken(user) {
  return jwt.sign({ userId: user.id }, secret(), {
    algorithm: 'HS256', expiresIn: SESSION_SECONDS,
  });
}

function verifyToken(token) {
  return jwt.verify(token, secret(), { algorithms: ['HS256'] });
}

module.exports = { issueToken, verifyToken, SESSION_SECONDS };
