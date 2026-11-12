-- PetVida — schema PostgreSQL (NeonDB)
-- Execute no SQL Editor do Neon ou: psql "$DATABASE_URL" -f database/schema.sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  email         TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  role          TEXT NOT NULL CHECK (role IN ('owner','vet')),   -- um utilizador, um papel
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX users_email_uq ON users (lower(email));

CREATE TABLE password_resets (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  code_hash  TEXT NOT NULL,
  attempts   INT  NOT NULL DEFAULT 0,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE pets (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  photo_url  TEXT,
  breed      TEXT,
  birth_date DATE,
  sex        TEXT CHECK (sex IN ('male','female')),
  weight_kg  NUMERIC(6,2),
  color      TEXT,
  microchip  TEXT,
  notes      TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX pets_owner_idx ON pets(owner_id);

-- Ligação dono <-> veterinário (convite por e-mail).
-- Desligar NUNCA apaga dados do veterinário: apenas muda status para 'disconnected'.
CREATE TABLE pet_vets (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id          UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  vet_email       TEXT NOT NULL,
  vet_id          UUID REFERENCES users(id),
  status          TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','accepted','declined','disconnected')),
  invited_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  responded_at    TIMESTAMPTZ,
  disconnected_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX pet_vets_uq ON pet_vets (pet_id, lower(vet_email));
CREATE INDEX pet_vets_vet_idx ON pet_vets (vet_id, status);

CREATE TABLE vaccines (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id      UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  applied_on  DATE NOT NULL,
  next_due_on DATE,
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE weight_records (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id      UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  weight_kg   NUMERIC(6,2) NOT NULL CHECK (weight_kg > 0),
  recorded_on DATE NOT NULL,
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE diet_entries (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id     UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  food       TEXT NOT NULL,
  amount     TEXT,
  meal_time  TIME,
  notes      TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE routines (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id      UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  time_of_day TIME NOT NULL,
  days        TEXT,              -- dias ISO "1,2,3" (1=Seg..7=Dom); NULL = todos os dias
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE symptoms (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id      UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  severity    TEXT CHECK (severity IN ('low','medium','high')),
  occurred_at TIMESTAMPTZ NOT NULL,
  image_url   TEXT,
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE pet_images (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id      UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  url         TEXT NOT NULL,
  public_id   TEXT,
  caption     TEXT,
  uploaded_by UUID REFERENCES users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Recomendações / sugestões / prescrições.
-- Sem FK para pet_vets: desligar um veterinário não afeta estes registos.
CREATE TABLE vet_notes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id     UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  vet_id     UUID NOT NULL REFERENCES users(id),
  type       TEXT NOT NULL CHECK (type IN ('recommendation','suggestion','prescription')),
  title      TEXT NOT NULL,
  content    TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX vet_notes_pet_idx ON vet_notes(pet_id, created_at DESC);

CREATE TABLE prescriptions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id         UUID NOT NULL UNIQUE REFERENCES vet_notes(id) ON DELETE CASCADE,
  medication      TEXT NOT NULL,
  dosage          TEXT NOT NULL,
  frequency_hours INT  NOT NULL CHECK (frequency_hours BETWEEN 1 AND 168),
  duration_days   INT  NOT NULL CHECK (duration_days BETWEEN 1 AND 365),
  start_at        TIMESTAMPTZ NOT NULL
);
CREATE TABLE prescription_doses (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
  scheduled_at    TIMESTAMPTZ NOT NULL,
  administered    BOOLEAN NOT NULL DEFAULT false,
  administered_at TIMESTAMPTZ
);
CREATE INDEX doses_rx_idx ON prescription_doses(prescription_id, scheduled_at);
