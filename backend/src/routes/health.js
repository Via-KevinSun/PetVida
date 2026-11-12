// CRUD genérico dos registos de saúde. Dono: leitura/escrita. Veterinário ligado: só leitura.
const router = require('express').Router({ mergeParams: true });
const db = require('../config/db');
const { HttpError, wrap } = require('../utils/errors');
const { clean } = require('../utils/validate');
const { getPetAccess, requireOwnerOfPet, assertUuid } = require('../utils/access');

const KINDS = {
  vaccines: { table: 'vaccines', order: 'applied_on DESC, created_at DESC',
    spec: { name: 'text!', applied_on: 'date!', next_due_on: 'date', notes: 'text' } },
  weights: { table: 'weight_records', order: 'recorded_on DESC, created_at DESC',
    spec: { weight_kg: 'num!', recorded_on: 'date!', notes: 'text' } },
  diets: { table: 'diet_entries', order: 'created_at DESC',
    spec: { food: 'text!', amount: 'text', meal_time: 'time', notes: 'text' } },
  routines: { table: 'routines', order: 'time_of_day ASC',
    spec: { title: 'text!', time_of_day: 'time!', days: 'days', notes: 'text' } },
  symptoms: { table: 'symptoms', order: 'occurred_at DESC',
    spec: { description: 'text!', severity: 'sev', occurred_at: 'ts!', image_url: 'text', notes: 'text' } },
};

function kindOf(req) {
  const k = KINDS[req.params.kind];
  if (!k) throw new HttpError(404, 'Recurso não encontrado');
  return k;
}

// Mantém pets.weight_kg igual ao registo de peso mais recente.
async function syncWeight(petId) {
  await db.query(
    `UPDATE pets SET weight_kg = (SELECT weight_kg FROM weight_records WHERE pet_id=$1
       ORDER BY recorded_on DESC, created_at DESC LIMIT 1) WHERE id=$1`, [petId]);
}

router.get('/:kind', wrap(async (req, res) => {
  const k = kindOf(req);
  await getPetAccess(req.user, req.params.petId);
  const { rows } = await db.query(`SELECT * FROM ${k.table} WHERE pet_id=$1 ORDER BY ${k.order}`, [req.params.petId]);
  res.json(rows);
}));

router.post('/:kind', wrap(async (req, res) => {
  const k = kindOf(req);
  await requireOwnerOfPet(req.user, req.params.petId);
  const d = clean(k.spec, req.body);
  const cols = Object.keys(k.spec);
  const { rows } = await db.query(
    `INSERT INTO ${k.table}(pet_id, ${cols.join(',')}) VALUES($1, ${cols.map((_, i) => '$' + (i + 2)).join(',')}) RETURNING *`,
    [req.params.petId, ...cols.map((c) => d[c])]);
  if (k.table === 'weight_records') await syncWeight(req.params.petId);
  res.status(201).json(rows[0]);
}));

router.put('/:kind/:id', wrap(async (req, res) => {
  const k = kindOf(req);
  assertUuid(req.params.id);
  await requireOwnerOfPet(req.user, req.params.petId);
  const d = clean(k.spec, req.body);
  const cols = Object.keys(k.spec);
  const { rows } = await db.query(
    `UPDATE ${k.table} SET ${cols.map((c, i) => `${c}=$${i + 1}`).join(',')}
     WHERE id=$${cols.length + 1} AND pet_id=$${cols.length + 2} RETURNING *`,
    [...cols.map((c) => d[c]), req.params.id, req.params.petId]);
  if (!rows[0]) throw new HttpError(404, 'Registo não encontrado');
  if (k.table === 'weight_records') await syncWeight(req.params.petId);
  res.json(rows[0]);
}));

router.delete('/:kind/:id', wrap(async (req, res) => {
  const k = kindOf(req);
  assertUuid(req.params.id);
  await requireOwnerOfPet(req.user, req.params.petId);
  const r = await db.query(`DELETE FROM ${k.table} WHERE id=$1 AND pet_id=$2`, [req.params.id, req.params.petId]);
  if (!r.rowCount) throw new HttpError(404, 'Registo não encontrado');
  if (k.table === 'weight_records') await syncWeight(req.params.petId);
  res.status(204).end();
}));

module.exports = router;
