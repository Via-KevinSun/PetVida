// Lembretes do dono (vacinas, doses e rotinas). O app agenda as notificações locais a partir disto.
const router = require('express').Router();
const db = require('../config/db');
const { auth, requireRole } = require('../middleware/auth');
const { wrap } = require('../utils/errors');

router.get('/', auth, requireRole('owner'), wrap(async (req, res) => {
  const [vac, doses, routines] = await Promise.all([
    db.query(
      `SELECT v.id, p.id AS pet_id, p.name AS pet_name, v.name AS title, v.next_due_on AS date
       FROM vaccines v JOIN pets p ON p.id=v.pet_id
       WHERE p.owner_id=$1 AND v.next_due_on >= current_date ORDER BY v.next_due_on`, [req.user.id]),
    db.query(
      `SELECT d.id, p.id AS pet_id, p.name AS pet_name, pr.medication AS title, pr.dosage AS subtitle, d.scheduled_at AS at
       FROM prescription_doses d JOIN prescriptions pr ON pr.id=d.prescription_id
       JOIN vet_notes n ON n.id=pr.note_id JOIN pets p ON p.id=n.pet_id
       WHERE p.owner_id=$1 AND NOT d.administered
         AND d.scheduled_at BETWEEN now() - interval '1 day' AND now() + interval '14 days'
       ORDER BY d.scheduled_at`, [req.user.id]),
    db.query(
      `SELECT r.id, p.id AS pet_id, p.name AS pet_name, r.title, r.time_of_day, r.days
       FROM routines r JOIN pets p ON p.id=r.pet_id WHERE p.owner_id=$1 ORDER BY r.time_of_day`, [req.user.id]),
  ]);
  res.json([
    ...vac.rows.map((r) => ({ ...r, type: 'vaccine', title: `Vacina: ${r.title}` })),
    ...doses.rows.map((r) => ({ ...r, type: 'dose', title: `Medicação: ${r.title}` })),
    ...routines.rows.map((r) => ({ ...r, type: 'routine' })),
  ]);
}));
module.exports = router;
