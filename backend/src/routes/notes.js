// Recomendações, sugestões, prescrições e doses.
const express = require('express');
const db = require('../config/db');
const { auth, requireRole } = require('../middleware/auth');
const { HttpError, wrap } = require('../utils/errors');
const { clean } = require('../utils/validate');
const { getPetAccess, assertUuid } = require('../utils/access');

const NOTE_SELECT = `
  SELECT n.id, n.pet_id, n.vet_id, n.type, n.title, n.content, n.created_at, u.name AS vet_name,
    EXISTS (SELECT 1 FROM pet_vets pv WHERE pv.pet_id=n.pet_id AND pv.vet_id=n.vet_id AND pv.status='accepted') AS vet_active,
    pr.id AS prescription_id, pr.medication, pr.dosage, pr.frequency_hours, pr.duration_days, pr.start_at,
    (SELECT count(*) FROM prescription_doses d WHERE d.prescription_id=pr.id)::int AS total_doses,
    (SELECT count(*) FROM prescription_doses d WHERE d.prescription_id=pr.id AND d.scheduled_at<=now())::int AS due_doses,
    (SELECT count(*) FROM prescription_doses d WHERE d.prescription_id=pr.id AND d.administered)::int AS given_doses,
    (SELECT count(*) FROM prescription_doses d WHERE d.prescription_id=pr.id AND d.administered AND d.scheduled_at<=now())::int AS taken_due_doses
  FROM vet_notes n JOIN users u ON u.id=n.vet_id
  LEFT JOIN prescriptions pr ON pr.note_id=n.id`;

const withAdherence = (r) => ({
  ...r,
  adherence_rate: r.prescription_id && r.due_doses > 0 ? Math.round((r.taken_due_doses / r.due_doses) * 100) : null,
});

// ---------- /pets/:petId/notes ----------
const petNotes = express.Router({ mergeParams: true });

petNotes.get('/', wrap(async (req, res) => {
  await getPetAccess(req.user, req.params.petId);
  const { rows } = await db.query(`${NOTE_SELECT} WHERE n.pet_id=$1 ORDER BY n.created_at DESC`, [req.params.petId]);
  res.json(rows.map(withAdherence));
}));

petNotes.post('/', requireRole('vet'), wrap(async (req, res) => {
  await getPetAccess(req.user, req.params.petId); // vet precisa de ligação ativa
  const type = req.body.type;
  if (!['recommendation', 'suggestion', 'prescription'].includes(type)) throw new HttpError(400, 'Tipo inválido');
  const base = clean({ title: 'text!', content: 'text' }, req.body);
  let rx = null;
  if (type === 'prescription') {
    rx = clean({ medication: 'text!', dosage: 'text!', start_at: 'ts' }, req.body);
    const freq = parseInt(req.body.frequency_hours, 10);
    const days = parseInt(req.body.duration_days, 10);
    if (!(freq >= 1 && freq <= 168)) throw new HttpError(400, 'frequency_hours deve estar entre 1 e 168');
    if (!(days >= 1 && days <= 365)) throw new HttpError(400, 'duration_days deve estar entre 1 e 365');
    rx.freq = freq; rx.days = days;
    rx.start = rx.start_at ? new Date(rx.start_at) : new Date();
  }
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query(
      'INSERT INTO vet_notes(pet_id,vet_id,type,title,content) VALUES($1,$2,$3,$4,$5) RETURNING id',
      [req.params.petId, req.user.id, type, base.title, base.content]);
    if (rx) {
      const { rows: p } = await client.query(
        `INSERT INTO prescriptions(note_id,medication,dosage,frequency_hours,duration_days,start_at)
         VALUES($1,$2,$3,$4,$5,$6) RETURNING id`,
        [rows[0].id, rx.medication, rx.dosage, rx.freq, rx.days, rx.start.toISOString()]);
      // Geração automática das doses: duração*24/frequência, a partir de start_at.
      const total = Math.max(1, Math.floor((rx.days * 24) / rx.freq));
      const times = Array.from({ length: total }, (_, i) => new Date(rx.start.getTime() + i * rx.freq * 3600000).toISOString());
      await client.query(
        'INSERT INTO prescription_doses(prescription_id, scheduled_at) SELECT $1, unnest($2::timestamptz[])',
        [p[0].id, times]);
    }
    await client.query('COMMIT');
    const { rows: out } = await db.query(`${NOTE_SELECT} WHERE n.id=$1`, [rows[0].id]);
    res.status(201).json(withAdherence(out[0]));
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}));

// ---------- rotas de topo ----------
const router = express.Router();
router.use(auth);

// Só o autor edita/apaga, e só enquanto estiver ligado ao pet.
async function ownNote(req) {
  assertUuid(req.params.id);
  const { rows } = await db.query(
    `SELECT n.* FROM vet_notes n JOIN pet_vets pv ON pv.pet_id=n.pet_id AND pv.vet_id=n.vet_id AND pv.status='accepted'
     WHERE n.id=$1 AND n.vet_id=$2`, [req.params.id, req.user.id]);
  if (!rows[0]) throw new HttpError(404, 'Registo não encontrado');
  return rows[0];
}
// Prescrições: só título/conteúdo são editáveis (as doses já geradas não mudam).
router.put('/notes/:id', requireRole('vet'), wrap(async (req, res) => {
  const n = await ownNote(req);
  const d = clean({ title: 'text!', content: 'text' }, req.body);
  await db.query('UPDATE vet_notes SET title=$1, content=$2 WHERE id=$3', [d.title, d.content, n.id]);
  const { rows } = await db.query(`${NOTE_SELECT} WHERE n.id=$1`, [n.id]);
  res.json(withAdherence(rows[0]));
}));
router.delete('/notes/:id', requireRole('vet'), wrap(async (req, res) => {
  const n = await ownNote(req);
  await db.query('DELETE FROM vet_notes WHERE id=$1', [n.id]);
  res.status(204).end();
}));

router.get('/prescriptions/:id/doses', wrap(async (req, res) => {
  assertUuid(req.params.id);
  const { rows: pr } = await db.query(
    'SELECT n.pet_id FROM prescriptions p JOIN vet_notes n ON n.id=p.note_id WHERE p.id=$1', [req.params.id]);
  if (!pr[0]) throw new HttpError(404, 'Prescrição não encontrada');
  await getPetAccess(req.user, pr[0].pet_id);
  const { rows } = await db.query(
    'SELECT id, scheduled_at, administered, administered_at FROM prescription_doses WHERE prescription_id=$1 ORDER BY scheduled_at',
    [req.params.id]);
  res.json(rows);
}));

// O dono marca/desmarca cada dose.
router.patch('/doses/:id', requireRole('owner'), wrap(async (req, res) => {
  assertUuid(req.params.id);
  const done = req.body.administered === true;
  const { rows } = await db.query(
    `UPDATE prescription_doses d SET administered=$1, administered_at=CASE WHEN $1 THEN now() ELSE NULL END
     FROM prescriptions p, vet_notes n, pets pt
     WHERE d.id=$2 AND p.id=d.prescription_id AND n.id=p.note_id AND pt.id=n.pet_id AND pt.owner_id=$3
     RETURNING d.id, d.scheduled_at, d.administered, d.administered_at`, [done, req.params.id, req.user.id]);
  if (!rows[0]) throw new HttpError(404, 'Dose não encontrada');
  res.json(rows[0]);
}));

module.exports = { petNotes, router };
