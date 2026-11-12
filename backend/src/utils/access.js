const db = require('../config/db');
const { HttpError } = require('./errors');

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
function assertUuid(v, label = 'id') {
  if (!UUID.test(v || '')) throw new HttpError(400, `${label} inválido`);
}

/** Dono: só os seus pets. Veterinário: só pets com ligação 'accepted'. Caso contrário 404. */
async function getPetAccess(user, petId) {
  assertUuid(petId, 'petId');
  const { rows } =
    user.role === 'owner'
      ? await db.query('SELECT * FROM pets WHERE id=$1 AND owner_id=$2', [petId, user.id])
      : await db.query(
          `SELECT p.* FROM pets p JOIN pet_vets pv ON pv.pet_id = p.id
           WHERE p.id=$1 AND pv.vet_id=$2 AND pv.status='accepted'`,
          [petId, user.id]
        );
  if (!rows[0]) throw new HttpError(404, 'Pet não encontrado');
  return { pet: rows[0], isOwner: user.role === 'owner' };
}

async function requireOwnerOfPet(user, petId) {
  if (user.role !== 'owner') throw new HttpError(403, 'Apenas o dono pode fazer isto');
  return (await getPetAccess(user, petId)).pet;
}

module.exports = { assertUuid, getPetAccess, requireOwnerOfPet };
