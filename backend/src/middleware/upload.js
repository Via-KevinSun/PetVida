const multer = require('multer');
const { HttpError } = require('../utils/errors');

module.exports = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (_req, file, cb) =>
    /^image\/(jpe?g|png|webp|gif|heic|heif)$/i.test(file.mimetype)
      ? cb(null, true)
      : cb(new HttpError(400, 'Apenas imagens são permitidas')),
}).single('image');
