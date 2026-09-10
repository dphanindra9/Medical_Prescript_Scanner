const express = require('express');
const router = express.Router();
const upload = require('../middleware/upload');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getReminders,
  setDoseTaken,
  addReminder,
  updateReminder,
  deleteReminder,
  identifyMedicineImage
} = require('../controllers/reminderController');

// All reminder routes require authentication
router.use(authenticateToken);

router.get('/', getReminders);
router.post('/', addReminder);
router.put('/:id', updateReminder);
router.put('/:id/dose', setDoseTaken);
router.delete('/:id', deleteReminder);

// Special AI identification endpoint using multer for image upload
router.post('/identify', upload.single('image'), identifyMedicineImage);

module.exports = router;
