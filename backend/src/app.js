const express = require('express');
const cors = require('cors');
const path = require('path');
const prescriptionRoutes = require('./routes/prescriptionRoutes');
const authRoutes = require('./routes/authRoutes');

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploaded images statically (careful in production, fine for MVP)
app.use('/uploads', express.static(path.join(__dirname, '../../uploads')));

// Routes
app.use('/api/prescriptions', prescriptionRoutes);
app.use('/api/auth', authRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: err.message || 'Something went wrong!' });
});

module.exports = app;
