const multer = require('multer');
const path = require('path');
const fs = require('fs');

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.resolve(__dirname, '../../', process.env.UPLOADS_DIR || 'uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    let ext = path.extname(file.originalname);
    if (!ext) ext = '.jpg'; // Fallback if flutter doesn't send extension
    cb(null, 'scan-' + uniqueSuffix + ext);
  }
});

const fileFilter = (req, file, cb) => {
  // Be more lenient for Flutter HTTP multipart uploads which might send application/octet-stream
  // or missing extensions. Since this is an MVP, we just allow the upload.
  cb(null, true);
};

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
  fileFilter: fileFilter
});

module.exports = upload;
