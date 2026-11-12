// Gestão de veterinários de um pet (lado do DONO).
const router = require('express').Router({ mergeParams: true });
const db = require('../config/db');
const { HttpError, wrap } = require('../utils/errors');
const { requireOwnerOfPet } = require('../utils/access');

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

router.get('/', wrap(async (req, res) => {
  await requireOwnerOfPet(req.user, req.params.petId);
  const { rows } = await db.query(
    `SELECT pv.id, pv.vet_email, pv.status, pv.invited_at, pv.responded_at, pv.disconnected_at, u.name AS vet_name
     FROM pet_vets pv LEFT JOIN users u ON u.id = pv.vet_id
     WHERE pv.pet_id=$1 ORDER BY pv.invited_at DESC`, [req.params.petId]);
  res.json(rows);
}));

router.post('/', wrap(async (req, res) => {
  const pet = await requireOwnerOfPet(req.user, req.params.petId);
  const email = String(req.body.email || '').trim();
  if (!EMAIL.test(email)) throw new HttpError(400, 'E-mail inválido');
  const { rows: me } = await db.query('SELECT email FROM users WHERE id=$1', [req.user.id]);
  if (me[0].email.toLowerCase() === email.toLowerCase()) throw new HttpError(400, 'Não pode convidar a si próprio');
  const { rows: u } = await db.query('SELECT role FROM users WHERE lower(email)=lower($1)', [email]);
  if (u[0] && u[0].role !== 'vet') throw new HttpError(400, 'Este utilizador não é veterinário');

  const { rows: ex } = await db.query(
    'SELECT * FROM pet_vets WHERE pet_id=$1 AND lower(vet_email)=lower($2)', [pet.id, email]);
  if (ex[0] && ['pending', 'accepted'].includes(ex[0].status))
    throw new HttpError(409, ex[0].status === 'pending' ? 'Convite já enviado' : 'Veterinário já está ligado');
  const q = ex[0]
    ? db.query(`UPDATE pet_vets SET status='pending', vet_id=NULL, invited_at=now(), responded_at=NULL,
                disconnected_at=NULL WHERE id=$1 RETURNING *`, [ex[0].id])
    : db.query('INSERT INTO pet_vets(pet_id, vet_email) VALUES($1,$2) RETURNING *', [pet.id, email]);
  res.status(201).json((await q).rows[0]);
}));

module.exports = router;
