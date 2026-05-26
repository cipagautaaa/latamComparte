const express  = require('express');
const router   = express.Router();
const ctrl     = require('../controllers/solicitudController');
const { verificarToken, verificarRol, filtrarPorPais } = require('../middleware/auth');
const { ROLES, ROLES_ADMIN, ROLES_CONTENT } = require('../constants/roles');
const { validarId } = require('../helpers/filtro');

// ─── Público ─────────────────────────────────────────────────────────────────
router.post('/', ctrl.crearSolicitudValidation, ctrl.crearSolicitud);

// ─── OJO: estas rutas van ANTES de /:id ──────────────────────────────────────
// Express evalúa en orden: sin esto, 'estadisticas' y 'mi-solicitud' serían
// capturados como si fueran ObjectIds, provocando errores de validación.

// Solo visitante: devuelve sus propias solicitudes por correo
router.get('/mi-solicitud', verificarToken, verificarRol(ROLES.VISITANTE), ctrl.miSolicitud);

// Estadísticas accesibles a todos los roles de contenido/admin
router.get('/estadisticas/resumen', verificarToken, verificarRol(...ROLES_CONTENT), filtrarPorPais, ctrl.estadisticasResumen);

// ─── CRUD administrativo ──────────────────────────────────────────────────────
// validarId corta el request antes de que Mongoose lance un CastError
router.get('/',             verificarToken, verificarRol(...ROLES_ADMIN), filtrarPorPais, ctrl.listarSolicitudes);
router.get('/:id',          verificarToken, verificarRol(...ROLES_ADMIN), filtrarPorPais, validarId, ctrl.detalleSolicitud);
router.patch('/:id/estado', verificarToken, verificarRol(...ROLES_ADMIN), filtrarPorPais, validarId, ctrl.actualizarEstado);
router.delete('/:id',       verificarToken, verificarRol(...ROLES_ADMIN), filtrarPorPais, validarId, ctrl.eliminarSolicitud);

module.exports = router;
