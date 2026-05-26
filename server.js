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
const dashboardRoutes   = require('./routes/dashboard');

const app = express();

// Cabeceras de seguridad HTTP (X-Frame-Options, X-Content-Type, etc.)
app.use(helmet());

// CORS: en dev acepta cualquier origen; en prod poner el dominio real en .env
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// 1 MB es suficiente para un CMS de texto; 10 MB facilitaría ataques DoS
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

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
app.use('/api/dashboard',   dashboardRoutes);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Latinoamérica Comparte API funcionando' });
});

// 404 — ruta no registrada
app.use((req, res) => {
  res.status(404).json({ message: 'Ruta no encontrada' });
});

// Manejador global de errores
app.use((err, req, res, next) => { // eslint-disable-line no-unused-vars
  console.error(err.stack);
  res.status(err.status || 500).json({ message: err.message || 'Error interno del servidor' });
});

const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
  console.log(`📱 API disponible en http://localhost:${PORT}/api`);
});

// Graceful shutdown: cierra conexiones abiertas antes de salir.
// Evita pérdida de datos y permite que el orquestador (PM2, Docker) reinicie limpiamente.
const shutdown = (signal) => {
  console.log(`\n${signal} recibido. Cerrando servidor...`);
  server.close(() => {
    mongoose.connection.close(false).then(() => {
      console.log('✅ Conexiones cerradas. Servidor apagado.');
      process.exit(0);
    });
  });
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT',  () => shutdown('SIGINT'));

module.exports = app;
