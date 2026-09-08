const { initDb } = require('./src/database/db');
initDb().then(() => {
  console.log("DB_TEST_SUCCESS");
  process.exit(0);
}).catch(err => {
  console.error("DB_TEST_FAIL", err);
  process.exit(1);
});
