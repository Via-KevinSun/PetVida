const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../config/db');
const { auth } = require('../middleware/auth');
const { HttpError, wrap } = require('../utils/errors');
const { sendMail } = require('../utils/mailer');

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const publicUser = (u) => ({ id: u.id, name: u.name, email: u.email, role: u.role });
const sign = (u) =>
  jwt.sign({ sub: u.id, role: u.role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });
const hashCode = (c) => crypto.createHash('sha256').update(c).digest('hex');

router.post('/register', wrap(async (req, res) => {
  const { name, email, password, role } = req.body;
  if (!name || !name.trim()) throw new HttpError(400, 'Nome obrigatório');
  if (!EMAIL.test(email || '')) throw new HttpError(400, 'E-mail inválido');
  if (!password || password.length < 8) throw new HttpError(400, 'A senha deve ter pelo menos 8 caracteres');
  if (!['owner', 'vet'].includes(role)) throw new HttpError(400, 'Papel inválido (owner | vet)');
  const hash = await bcrypt.hash(password, 10);
  try {
    const { rows } = await db.query(
      'INSERT INTO users(name,email,password_hash,role) VALUES($1,$2,$3,$4) RETURNING *',
      [name.trim(), email.trim(), hash, role]
    );
    res.status(201).json({ token: sign(rows[0]), user: publicUser(rows[0]) });
  } catch (e) {
    if (e.code === '23505') throw new HttpError(409, 'Este e-mail já está registado');
    throw e;
  }
}));

router.post('/login', wrap(async (req, res) => {
  const { email, password } = req.body;
  const { rows } = await db.query('SELECT * FROM users WHERE lower(email)=lower($1)', [email || '']);
  const u = rows[0];
  if (!u || !(await bcrypt.compare(password || '', u.password_hash)))
    throw new HttpError(401, 'E-mail ou senha incorretos');
  res.json({ token: sign(u), user: publicUser(u) });
}));

router.get('/me', auth, wrap(async (req, res) => {
  const { rows } = await db.query('SELECT * FROM users WHERE id=$1', [req.user.id]);
  if (!rows[0]) throw new HttpError(401, 'Utilizador não existe');
  res.json({ user: publicUser(rows[0]) });
}));

// Recuperação de senha: código de 6 dígitos enviado por e-mail (válido 15 min, máx. 5 tentativas).
router.post('/forgot-password', wrap(async (req, res) => {
  const { email } = req.body;
  const { rows } = await db.query('SELECT * FROM users WHERE lower(email)=lower($1)', [email || '']);
  if (rows[0]) {
    const code = String(crypto.randomInt(100000, 1000000));
    await db.query('DELETE FROM password_resets WHERE user_id=$1', [rows[0].id]);
    await db.query(
      `INSERT INTO password_resets(user_id, code_hash, expires_at) VALUES($1,$2, now() + interval '15 minutes')`,
      [rows[0].id, hashCode(code)]
    );
    await sendMail({
      to: rows[0].email,
      subject: 'PetVida — código de recuperação de senha',
      text: `Olá ${rows[0].name},\n\nO seu código de recuperação é: ${code}\nVálido por 15 minutos.\n\nSe não pediu isto, ignore este e-mail.`,
    });
  }
  // Resposta igual quer o e-mail exista ou não (evita enumeração de contas).
  res.json({ message: 'Se o e-mail existir, enviámos um código de recuperação.' });
}));

router.post('/reset-password', wrap(async (req, res) => {
  const { email, code, password } = req.body;
  if (!password || password.length < 8) throw new HttpError(400, 'A senha deve ter pelo menos 8 caracteres');
  const bad = new HttpError(400, 'Código inválido ou expirado');
  const { rows } = await db.query(
    `SELECT pr.*, u.id AS uid FROM password_resets pr JOIN users u ON u.id = pr.user_id
     WHERE lower(u.email)=lower($1)`, [email || '']);
  const pr = rows[0];
  if (!pr || pr.attempts >= 5 || new Date(pr.expires_at) < new Date()) throw bad;
  if (hashCode(String(code || '')) !== pr.code_hash) {
    await db.query('UPDATE password_resets SET attempts = attempts + 1 WHERE id=$1', [pr.id]);
    throw bad;
  }
  await db.query('UPDATE users SET password_hash=$1 WHERE id=$2', [await bcrypt.hash(password, 10), pr.uid]);
  await db.query('DELETE FROM password_resets WHERE user_id=$1', [pr.uid]);
  res.json({ message: 'Senha atualizada com sucesso' });
}));

module.exports = router;
