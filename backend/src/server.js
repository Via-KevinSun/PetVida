require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { notFound, errorHandler } = require('./middleware/error');

if (!process.env.JWT_SECRET || !process.env.DATABASE_URL) {
  console.error('Defina JWT_SECRET e DATABASE_URL no ficheiro .env');
  process.exit(1);
}

const app = express();
app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : true }));
app.use(express.json({ limit: '1mb' }));

app.get('/health', (_req, res) => res.json({ ok: true }));
app.use('/api/auth', require('./routes/auth'));
app.use('/api/pets', require('./routes/pets'));
app.use('/api/uploads', require('./routes/uploads'));
app.use('/api/reminders', require('./routes/reminders'));
app.use('/api', require('./routes/connections'));
app.use('/api', require('./routes/notes').router);

app.use(notFound);
app.use(errorHandler);

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`PetVida API a correr na porta ${port}`));
