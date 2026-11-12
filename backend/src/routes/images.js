const router = require('express').Router({ mergeParams: true });
const db = require('../config/db');
const upload = require('../middleware/upload');
const { uploadBuffer, cloudinary } = require('../config/cloudinary');
const { HttpError, wrap } = require('../utils/errors');
const { getPetAccess, requireOwnerOfPet, assertUuid } = require('../utils/access');

router.get('/', wrap(async (req, res) => {
  await getPetAccess(req.user, req.params.petId);
  const { rows } = await db.query('SELECT * FROM pet_images WHERE pet_id=$1 ORDER BY created_at DESC', [req.params.petId]);
  res.json(rows);
}));

// Galeria do pet (aparece na timeline). Campo multipart: "image" (+ "caption").
router.post('/', upload, wrap(async (req, res) => {
  await requireOwnerOfPet(req.user, req.params.petId);
  if (!req.file) throw new HttpError(400, 'Envie uma imagem no campo "image"');
  const up = await uploadBuffer(req.file.buffer, `petvida/pets/${req.params.petId}`);
  const { rows } = await db.query(
    'INSERT INTO pet_images(pet_id,url,public_id,caption,uploaded_by) VALUES($1,$2,$3,$4,$5) RETURNING *',
    [req.params.petId, up.secure_url, up.public_id, (req.body.caption || '').trim() || null, req.user.id]);
  res.status(201).json(rows[0]);
}));

router.delete('/:id', wrap(async (req, res) => {
  assertUuid(req.params.id);
  await requireOwnerOfPet(req.user, req.params.petId);
  const { rows } = await db.query('DELETE FROM pet_images WHERE id=$1 AND pet_id=$2 RETURNING public_id', [req.params.id, req.params.petId]);
  if (!rows[0]) throw new HttpError(404, 'Imagem não encontrada');
  if (rows[0].public_id) cloudinary.uploader.destroy(rows[0].public_id).catch(() => {});
  res.status(204).end();
}));

module.exports = router;
