const express = require('express');
const router = express.Router();
const upload = require('../middleware/upload');
const {
  scanPrescription,
  getAllPrescriptions,
  getPrescriptionById,
  deletePrescription
} = require('../controllers/prescriptionController');

const { authenticateToken } = require('../middleware/authMiddleware');

// Routes
router.use(authenticateToken); // Apply to all routes below
router.post('/scan', upload.single('image'), scanPrescription);
router.get('/', getAllPrescriptions);
router.get('/:id', getPrescriptionById);
router.delete('/:id', deletePrescription);

module.exports = router;
