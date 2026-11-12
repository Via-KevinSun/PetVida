const router = require('express').Router();
const db = require('../config/db');
const { auth } = require('../middleware/auth');
const { wrap } = require('../utils/errors');
const { clean } = require('../utils/validate');
const { getPetAccess, requireOwnerOfPet } = require('../utils/access');

const SPEC = {
  name: 'text!', photo_url: 'text', breed: 'text', birth_date: 'date', sex: 'sex',
  weight_kg: 'num', color: 'text', microchip: 'text', notes: 'text',
};
const COLS = Object.keys(SPEC);

router.use(auth);

router.get('/', wrap(async (req, res) => {
  const { rows } =
    req.user.role === 'owner'
      ? await db.query('SELECT * FROM pets WHERE owner_id=$1 ORDER BY name', [req.user.id])
      : await db.query(
          `SELECT p.*, u.name AS owner_name FROM pets p
           JOIN pet_vets pv ON pv.pet_id=p.id AND pv.vet_id=$1 AND pv.status='accepted'
           JOIN users u ON u.id=p.owner_id ORDER BY p.name`, [req.user.id]);
  res.json(rows);
}));

router.post('/', wrap(async (req, res) => {
  if (req.user.role !== 'owner') return res.status(403).json({ error: 'Apenas donos podem cadastrar pets' });
  const d = clean(SPEC, req.body);
  const { rows } = await db.query(
    `INSERT INTO pets(owner_id, ${COLS.join(',')}) VALUES($1, ${COLS.map((_, i) => '$' + (i + 2)).join(',')}) RETURNING *`,
    [req.user.id, ...COLS.map((c) => d[c])]);
  res.status(201).json(rows[0]);
}));

router.get('/:petId', wrap(async (req, res) => {
  const { pet } = await getPetAccess(req.user, req.params.petId);
  res.json(pet);
}));

router.put('/:petId', wrap(async (req, res) => {
  await requireOwnerOfPet(req.user, req.params.petId);
  const d = clean(SPEC, req.body);
  const { rows } = await db.query(
    `UPDATE pets SET ${COLS.map((c, i) => `${c}=$${i + 1}`).join(',')} WHERE id=$${COLS.length + 1} RETURNING *`,
    [...COLS.map((c) => d[c]), req.params.petId]);
  res.json(rows[0]);
}));

router.delete('/:petId', wrap(async (req, res) => {
  await requireOwnerOfPet(req.user, req.params.petId);
  await db.query('DELETE FROM pets WHERE id=$1', [req.params.petId]);
  res.status(204).end();
}));

// Sub-recursos (a ordem importa: rotas fixas antes do genérico /:kind)
router.use('/:petId/timeline', require('./timeline'));
router.use('/:petId/images', require('./images'));
router.use('/:petId/vets', require('./petVets'));
router.use('/:petId/notes', require('./notes').petNotes);
router.use('/:petId', require('./health'));

module.exports = router;
