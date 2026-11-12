const multer = require('multer');

const notFound = (_req, res) => res.status(404).json({ error: 'Rota não encontrada' });

// eslint-disable-next-line no-unused-vars
function errorHandler(err, _req, res, _next) {
  if (err instanceof multer.MulterError) return res.status(400).json({ error: 'Falha no upload: ' + err.message });
  if (err.status) return res.status(err.status).json({ error: err.message });
  if (err.code === '23505') return res.status(409).json({ error: 'Registo duplicado' });
  if (err.code === '23503') return res.status(400).json({ error: 'Referência inválida' });
  console.error(err);
  res.status(500).json({ error: 'Erro interno do servidor' });
}
module.exports = { notFound, errorHandler };
