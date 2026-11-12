// Convites (lado do VETERINÁRIO) e desligar ligação (dono OU veterinário).
const router = require('express').Router();
const db = require('../config/db');
const { auth, requireRole } = require('../middleware/auth');
const { HttpError, wrap } = require('../utils/errors');
const { assertUuid } = require('../utils/access');

router.use(auth);

router.get('/invites', requireRole('vet'), wrap(async (req, res) => {
  const { rows } = await db.query(
    `SELECT pv.id, pv.status, pv.invited_at, p.id AS pet_id, p.name AS pet_name, p.breed, p.photo_url, o.name AS owner_name
     FROM pet_vets pv
     JOIN pets p ON p.id=pv.pet_id JOIN users o ON o.id=p.owner_id
     JOIN users me ON lower(me.email)=lower(pv.vet_email)
     WHERE me.id=$1 AND pv.status='pending' ORDER BY pv.invited_at DESC`, [req.user.id]);
  res.json(rows);
}));

async function respond(req, res, status) {
  assertUuid(req.params.id);
  const { rows } = await db.query(
    `UPDATE pet_vets pv SET status=$1, vet_id=$2, responded_at=now()
     FROM users me WHERE pv.id=$3 AND pv.status='pending' AND me.id=$2 AND lower(me.email)=lower(pv.vet_email)
     RETURNING pv.*`, [status, req.user.id, req.params.id]);
  if (!rows[0]) throw new HttpError(404, 'Convite não encontrado');
  res.json(rows[0]);
}
router.post('/invites/:id/accept', requireRole('vet'), wrap((req, res) => respond(req, res, 'accepted')));
router.post('/invites/:id/decline', requireRole('vet'), wrap((req, res) => respond(req, res, 'declined')));

// Desligar: apenas altera o estado. vet_notes/prescriptions/doses permanecem intactos.
router.post('/connections/:id/disconnect', wrap(async (req, res) => {
  assertUuid(req.params.id);
  const { rows } = await db.query(
    `UPDATE pet_vets pv SET status='disconnected', disconnected_at=now()
     WHERE pv.id=$1 AND pv.status='accepted'
       AND (pv.vet_id=$2 OR EXISTS (SELECT 1 FROM pets p WHERE p.id=pv.pet_id AND p.owner_id=$2))
     RETURNING pv.*`, [req.params.id, req.user.id]);
  if (!rows[0]) throw new HttpError(404, 'Ligação não encontrada');
  res.json(rows[0]);
}));

module.exports = router;
