const express = require('express');
const router = express.Router();
const { signup, login } = require('../controllers/authController');
const { authenticateToken } = require('../middleware/authMiddleware');

router.post('/signup', signup);
router.post('/login', login);
router.get('/session', authenticateToken, (req, res) => {
  res.json({ user: req.authUser });
});

module.exports = router;
