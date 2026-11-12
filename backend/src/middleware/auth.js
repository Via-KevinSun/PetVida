const jwt = require('jsonwebtoken');
const { HttpError } = require('../utils/errors');

function auth(req, _res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return next(new HttpError(401, 'Não autenticado'));
  try {
    const p = jwt.verify(token, process.env.JWT_SECRET);
    req.user = { id: p.sub, role: p.role };
    next();
  } catch {
    next(new HttpError(401, 'Sessão inválida ou expirada'));
  }
}
const requireRole = (role) => (req, _res, next) =>
  req.user.role === role ? next() : next(new HttpError(403, 'Sem permissão para esta ação'));

module.exports = { auth, requireRole };
