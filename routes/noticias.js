const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/noticiaController');
const { verificarToken, verificarRol, filtrarPorPais } = require('../middleware/auth');
const { ROLES_ADMIN } = require('../constants/roles');
const { validarId }   = require('../helpers/filtro');

// Sin auth
router.get('/publico', ctrl.listarNoticiasPublico);

// Va antes de /:id para no ser capturada por el patrón dinámico
router.get('/dashboard/estadisticas', verificarToken, filtrarPorPais, ctrl.estadisticasDashboard);

// CRUD protegido
router.get('/',             verificarToken, filtrarPorPais, ctrl.listarNoticias);
router.get('/:id',          verificarToken, filtrarPorPais, validarId, ctrl.detalleNoticia);
router.post('/',            verificarToken, filtrarPorPais, ctrl.crearNoticiaValidation, ctrl.crearNoticia);
router.put('/:id',          verificarToken, filtrarPorPais, validarId, ctrl.editarNoticia);
router.patch('/:id/estado', verificarToken, filtrarPorPais, validarId, ctrl.cambiarEstado);
router.delete('/:id',       verificarToken, verificarRol(...ROLES_ADMIN), filtrarPorPais, validarId, ctrl.eliminarNoticia);

module.exports = router;
