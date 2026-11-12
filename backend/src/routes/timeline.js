const router = require('express').Router({ mergeParams: true });
const db = require('../config/db');
const { wrap } = require('../utils/errors');
const { getPetAccess } = require('../utils/access');

const NOTE_KINDS = ['recommendation', 'suggestion', 'prescription'];
const SIMPLE = {
  vaccine: `SELECT id, 'vaccine' AS kind, applied_on::timestamptz AS at, name AS title,
              CASE WHEN next_due_on IS NULL THEN notes ELSE 'Próxima dose: ' || next_due_on::text END AS description,
              NULL::text AS image_url, NULL::text AS vet_name, NULL::boolean AS vet_active
            FROM vaccines WHERE pet_id=$1`,
  weight: `SELECT id, 'weight', recorded_on::timestamptz, weight_kg::text || ' kg', notes, NULL, NULL, NULL
           FROM weight_records WHERE pet_id=$1`,
  symptom: `SELECT id, 'symptom', occurred_at, description, notes, image_url, NULL, NULL
            FROM symptoms WHERE pet_id=$1`,
  diet: `SELECT id, 'diet', created_at, food, concat_ws(' · ', amount, meal_time::text), NULL, NULL, NULL
         FROM diet_entries WHERE pet_id=$1`,
  image: `SELECT id, 'image', created_at, COALESCE(caption, 'Foto'), NULL, url, NULL, NULL
          FROM pet_images WHERE pet_id=$1`,
};

router.get('/', wrap(async (req, res) => {
  await getPetAccess(req.user, req.params.petId);
  const wanted = (req.query.kinds ? String(req.query.kinds).split(',') : [...Object.keys(SIMPLE), ...NOTE_KINDS]);
  const params = [req.params.petId];
  const parts = Object.keys(SIMPLE).filter((k) => wanted.includes(k)).map((k) => SIMPLE[k]);
  const noteKinds = NOTE_KINDS.filter((k) => wanted.includes(k));
  if (noteKinds.length) {
    params.push(noteKinds);
    // Prescrições/recomendações de veterinários desligados continuam visíveis (vet_active = false).
    parts.push(`SELECT n.id, n.type, n.created_at, n.title, n.content, NULL::text, u.name,
                  EXISTS (SELECT 1 FROM pet_vets pv WHERE pv.pet_id=n.pet_id AND pv.vet_id=n.vet_id AND pv.status='accepted')
                FROM vet_notes n JOIN users u ON u.id=n.vet_id WHERE n.pet_id=$1 AND n.type = ANY($2::text[])`);
  }
  if (!parts.length) return res.json([]);
  const limit = Math.min(parseInt(req.query.limit, 10) || 100, 300);
  const offset = Math.max(parseInt(req.query.offset, 10) || 0, 0);
  const { rows } = await db.query(
    `SELECT * FROM (${parts.join(' UNION ALL ')}) t(id, kind, at, title, description, image_url, vet_name, vet_active)
     ORDER BY at DESC LIMIT ${limit} OFFSET ${offset}`, params);
  res.json(rows);
}));
module.exports = router;
