const { getDb } = require('../database/db');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const fs = require('fs');
const path = require('path');
const { applyDose } = require('../services/inventoryService');

async function getReminders(req, res) {
  try {
    const userId = req.user.userId;
    const db = getDb();
    const result = await db.query('SELECT * FROM reminders WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching reminders:', error);
    res.status(500).json({ error: 'Failed to fetch reminders' });
  }
}

async function addReminder(req, res) {
  try {
    const userId = req.user.userId;
    const { medicine_name, pill_count, timings, days } = req.body;

    if (!medicine_name || timings == null || days == null || !Number.isInteger(pill_count) || pill_count < 0) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const db = getDb();
    const result = await db.query(
      'INSERT INTO reminders (user_id, medicine_name, pill_count, timings, days, initial_pill_count) VALUES ($1, $2, $3, $4, $5, $3) RETURNING *',
      [userId, medicine_name, pill_count || 0, JSON.stringify(timings), JSON.stringify(days)]
    );

    res.status(201).json({ message: 'Reminder created successfully', reminder: result.rows[0] });
  } catch (error) {
    console.error('Error adding reminder:', error);
    res.status(500).json({ error: 'Failed to create reminder' });
  }
}

async function deleteReminder(req, res) {
  try {
    const userId = req.user.userId;
    const { id } = req.params;

    const db = getDb();
    const result = await db.query('DELETE FROM reminders WHERE id = $1 AND user_id = $2 RETURNING *', [id, userId]);
    
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Reminder not found or unauthorized' });
    }

    res.json({ message: 'Reminder deleted' });
  } catch (error) {
    console.error('Error deleting reminder:', error);
    res.status(500).json({ error: 'Failed to delete reminder' });
  }
}

async function updateReminder(req, res) {
  try {
    const userId = req.user.userId;
    const { id } = req.params;
    const { medicine_name, pill_count, timings, days } = req.body;

    if (!medicine_name || timings == null || days == null || !Number.isInteger(pill_count) || pill_count < 0) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const db = getDb();
    const result = await db.query(
      `UPDATE reminders 
       SET medicine_name = $1, pill_count = $2, timings = $3, days = $4,
           initial_pill_count = CASE WHEN $2 > pill_count THEN $2 ELSE initial_pill_count END,
           low_stock_notified = CASE WHEN $2 > pill_count THEN FALSE ELSE low_stock_notified END
       WHERE id = $5 AND user_id = $6 
       RETURNING *`,
      [medicine_name, pill_count || 0, JSON.stringify(timings), JSON.stringify(days), id, userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Reminder not found or unauthorized' });
    }

    res.json({ message: 'Reminder updated successfully', reminder: result.rows[0] });
  } catch (error) {
    console.error('Error updating reminder:', error);
    res.status(500).json({ error: 'Failed to update reminder' });
  }
}

async function setDoseTaken(req, res) {
  const { date, time, taken } = req.body;
  if (typeof date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(date) ||
      !Number.isFinite(Date.parse(date)) || new Date(date).toISOString().slice(0, 10) !== date ||
      typeof time !== 'string' || !/^\d{2}:\d{2}$/.test(time) || typeof taken !== 'boolean') {
    return res.status(400).json({ error: 'A valid date, time and checkbox state are required' });
  }
  let client;
  try {
    client = await getDb().connect();
    await client.query('BEGIN');
    const result = await client.query(
      'SELECT * FROM reminders WHERE id = $1 AND user_id = $2 FOR UPDATE',
      [req.params.id, req.user.userId]
    );
    const reminder = result.rows[0];
    if (!reminder) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Reminder not found' });
    }
    const key = `${date}_${time}`;
    if (!reminder.timings.includes(time) && !reminder.taken_doses[key]) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Time is not in this reminder schedule' });
    }
    const change = applyDose(reminder, key, taken);
    const updated = await client.query(
      `UPDATE reminders SET pill_count = $1, taken_doses = $2, low_stock_notified = $3
       WHERE id = $4 RETURNING *`,
      [change.pill_count, JSON.stringify(change.taken_doses), change.low_stock_notified, reminder.id]
    );
    await client.query('COMMIT');
    res.json({ reminder: updated.rows[0], notify_low_stock: change.notify });
  } catch (error) {
    if (client) await client.query('ROLLBACK');
    res.status(error.status || 500).json({ error: error.status ? error.message : 'Failed to update inventory' });
  } finally {
    if (client) client.release();
  }
}

async function identifyMedicineImage(req, res) {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image uploaded' });
    }

    const imagePath = req.file.path;
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey || apiKey === 'your_api_key_here') {
      return res.status(500).json({ error: 'Gemini API Key missing' });
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

    const ext = path.extname(imagePath).toLowerCase();
    let mimeType = "image/jpeg";
    if (ext === '.png') mimeType = "image/png";
    else if (ext === '.webp') mimeType = "image/webp";

    const imageParts = [
      {
        inlineData: {
          data: Buffer.from(fs.readFileSync(imagePath)).toString("base64"),
          mimeType: mimeType
        }
      }
    ];

    const prompt = `
      You are an AI that helps patients identify their medicine by looking at a photo of the pill bottle, blister pack, or prescription label.
      Your goal is to extract JUST the medicine name (and dosage if clearly visible, e.g., 'Paracetamol 500mg').
      If the image is too blurry, dark, cut off, or doesn't look like medicine/label, return EXACTLY this JSON: {"error": true, "message": "Image is not clear. Please enter the name manually."}
      If you can read it clearly, return EXACTLY this JSON: {"error": false, "name": "The Medicine Name"}
      Do NOT include any markdown code blocks, just raw JSON.
    `;

    const result = await model.generateContent([prompt, ...imageParts]);
    const responseText = result.response.text().replace(/```json/gi, '').replace(/```/gi, '').trim();
    
    const parsedData = JSON.parse(responseText);

    // Clean up file if we don't want to store reminder images long-term (or keep it if needed, we'll keep for MVP)
    // fs.unlinkSync(imagePath);

    res.json(parsedData);

  } catch (error) {
    console.error('Error identifying medicine:', error);
    res.status(500).json({ error: true, message: 'Failed to identify medicine due to an internal error. Please enter manually.' });
  }
}

module.exports = {
  setDoseTaken,
  getReminders,
  addReminder,
  updateReminder,
  deleteReminder,
  identifyMedicineImage
};
