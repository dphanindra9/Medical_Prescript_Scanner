const { getDb } = require('../database/db');
const { processPrescriptionImage } = require('../services/prescriptionService');

async function scanPrescription(req, res) {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image uploaded' });
    }

    const imagePath = req.file.path;
    const userId = req.user.userId; // Extracted from JWT token

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized: Missing user ID in token' });
    }
    
    // Process the image to extract info
    const extractedData = await processPrescriptionImage(imagePath);
    
    // Save to database
    const db = getDb();
    
    const result = await db.query(
      `INSERT INTO prescriptions (patient_name, doctor_name, prescription_date, instructions, raw_text, image_path, user_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
      [
        extractedData.patientName,
        extractedData.doctorName,
        extractedData.date,
        extractedData.instructions,
        extractedData.rawText,
        req.file.filename,
        userId
      ]
    );

    const prescriptionId = result.rows[0].id;

    // Save medicines
    for (const med of extractedData.medicines) {
      await db.query(
        `INSERT INTO medicines (prescription_id, name, dosage, frequency, duration)
         VALUES ($1, $2, $3, $4, $5)`,
        [prescriptionId, med.name, med.dosage, med.frequency, med.duration]
      );
    }

    res.status(201).json({
      message: 'Prescription scanned and saved',
      data: {
        id: prescriptionId,
        ...extractedData
      }
    });

  } catch (error) {
    console.error('Error in scanPrescription:', error);
    res.status(500).json({ error: 'Failed to process prescription image' });
  }
}

async function getAllPrescriptions(req, res) {
  try {
    const userId = req.user.userId; // Extracted from JWT token
    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized: Missing user ID in token' });
    }

    const db = getDb();
    const result = await db.query('SELECT * FROM prescriptions WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch prescriptions' });
  }
}

async function getPrescriptionById(req, res) {
  try {
    const db = getDb();
    const { id } = req.params;
    const userId = req.user.userId;
    
    const pResult = await db.query('SELECT * FROM prescriptions WHERE id = $1 AND user_id = $2', [id, userId]);
    if (pResult.rows.length === 0) {
      return res.status(404).json({ error: 'Prescription not found or unauthorized' });
    }
    
    const prescription = pResult.rows[0];
    
    const mResult = await db.query('SELECT * FROM medicines WHERE prescription_id = $1', [id]);
    prescription.medicines = mResult.rows;
    
    res.json(prescription);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch prescription details' });
  }
}

async function deletePrescription(req, res) {
  try {
    const db = getDb();
    const { id } = req.params;
    const userId = req.user.userId;
    
    const result = await db.query('DELETE FROM prescriptions WHERE id = $1 AND user_id = $2', [id, userId]);
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Prescription not found or unauthorized' });
    }
    
    // NOTE: ON DELETE CASCADE handles medicines table
    res.json({ message: 'Prescription deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete prescription' });
  }
}

module.exports = {
  scanPrescription,
  getAllPrescriptions,
  getPrescriptionById,
  deletePrescription
};
