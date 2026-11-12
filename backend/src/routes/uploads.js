// Upload avulso (foto do pet, foto de sintoma). Devolve apenas a URL do Cloudinary.
const router = require('express').Router();
const { auth, requireRole } = require('../middleware/auth');
const upload = require('../middleware/upload');
const { uploadBuffer } = require('../config/cloudinary');
const { HttpError, wrap } = require('../utils/errors');

router.post('/', auth, requireRole('owner'), upload, wrap(async (req, res) => {
  if (!req.file) throw new HttpError(400, 'Envie uma imagem no campo "image"');
  const up = await uploadBuffer(req.file.buffer, `petvida/users/${req.user.id}`);
  res.status(201).json({ url: up.secure_url, public_id: up.public_id });
}));
module.exports = router;
