require('dotenv').config();
const app = require('./src/app');
const { initDb } = require('./src/database/db');

const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    await initDb();
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server is running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();
