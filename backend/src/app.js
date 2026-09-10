const express = require('express');
const cors = require('cors');
const path = require('path');
const prescriptionRoutes = require('./routes/prescriptionRoutes');
const authRoutes = require('./routes/authRoutes');
const reminderRoutes = require('./routes/reminderRoutes');

const app = express();

app.use(cors({ exposedHeaders: ['X-Session-Token'] }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploaded images statically (careful in production, fine for MVP)
app.use('/uploads', express.static(path.join(__dirname, '../../uploads')));

// Routes
app.use('/api/prescriptions', prescriptionRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/reminders', reminderRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: err.message || 'Something went wrong!' });
});

module.exports = app;
