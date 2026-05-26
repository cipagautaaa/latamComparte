const express  = require('express');
const router   = express.Router();
const ctrl     = require('../controllers/solicitudController');
const { verificarToken, verificarRol, filtrarPorPais } = require('../middleware/auth');
const { ROLES, ROLES_ADMIN } = require('../constants/roles');
const { validarId } = require('../helpers/filtro');

// Público
router.post('/', ctrl.crearSolicitudValidation, ctrl.crearSolicitud);

// OJO: estas dos rutas van antes de /:id porque Express evalúa en orden
// y /:id capturaría 'estadisticas' o 'mi-solicitud' como si fueran ObjectIds
router.get('/estadisticas/resumen', verificarToken, filtrarPorPais, ctrl.estadisticasResumen);
router.get('/mi-solicitud',         verificarToken, verificarRol(ROLES.VISITANTE), ctrl.miSolicitud);

// Admin — validarId corta el request antes de que Mongoose lance un CastError
router.get('/',             verificarToken, verificarRol(...ROLES_ADMIN), filtrarPorPais, ctrl.listarSolicitudes);
router.get('/:id',          verificarToken, verificarRol(...ROLES_ADMIN), filtrarPorPais, validarId, ctrl.detalleSolicitud);
router.patch('/:id/estado', verificarToken, verificarRol(...ROLES_ADMIN), filtrarPorPais, validarId, ctrl.actualizarEstado);
router.delete('/:id',       verificarToken, verificarRol(...ROLES_ADMIN), filtrarPorPais, validarId, ctrl.eliminarSolicitud);

module.exports = router;
