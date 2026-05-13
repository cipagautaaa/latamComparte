require('dotenv').config();
const express    = require('express');
const mongoose   = require('mongoose');
const cors       = require('cors');
const helmet     = require('helmet');
const rateLimit  = require('express-rate-limit');

const authRoutes        = require('./routes/auth');
const paisesRoutes      = require('./routes/paises');
const solicitudesRoutes = require('./routes/solicitudes');
const testimoniosRoutes = require('./routes/testimonios');
const noticiasRoutes    = require('./routes/noticias');

const app = express();

// Cabeceras de seguridad HTTP (X-Frame-Options, X-Content-Type, etc.)
app.use(helmet());

// CORS: en dev acepta cualquier origen; en prod poner el dominio real en .env
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Límite general: 200 requests por 15 min por IP
const limiterGeneral = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Demasiadas peticiones, intenta más tarde' },
});

// Límite estricto para login: 10 intentos por 15 min — frena fuerza bruta
const limiterLogin = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Demasiados intentos de inicio de sesión, intenta más tarde' },
});

app.use('/api', limiterGeneral);
app.use('/api/auth/login', limiterLogin);

// Si la BD no conecta no tiene sentido arrancar el servidor
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('✅ MongoDB conectado'))
  .catch((err) => {
    console.error('❌ Error MongoDB:', err);
    process.exit(1);
  });

app.use('/api/auth',        authRoutes);
app.use('/api/paises',      paisesRoutes);
app.use('/api/solicitudes', solicitudesRoutes);
app.use('/api/testimonios', testimoniosRoutes);
app.use('/api/noticias',    noticiasRoutes);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Latinoamérica Comparte API funcionando' });
});

app.use((req, res) => {
  res.status(404).json({ message: 'Ruta no encontrada' });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({ message: err.message || 'Error interno del servidor' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
  console.log(`📱 API disponible en http://localhost:${PORT}/api`);
});

module.exports = app;
