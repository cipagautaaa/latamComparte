const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/testimonioController');
const { verificarToken, verificarRol, filtrarPorPais } = require('../middleware/auth');
const { ROLES_ADMIN } = require('../constants/roles');
const { validarId }   = require('../helpers/filtro');

// Sin auth
router.get('/publico', ctrl.listarTestimoniosPublico);

// Protegidos
router.get('/',             verificarToken, filtrarPorPais, ctrl.listarTestimonios);
router.get('/:id',          verificarToken, filtrarPorPais, validarId, ctrl.detalleTestimonio);
router.post('/',            verificarToken, filtrarPorPais, ctrl.crearTestimonioValidation, ctrl.crearTestimonio);
router.put('/:id',          verificarToken, filtrarPorPais, validarId, ctrl.editarTestimonio);
router.patch('/:id/estado', verificarToken, filtrarPorPais, validarId, ctrl.cambiarEstado);
router.delete('/:id',       verificarToken, verificarRol(...ROLES_ADMIN), filtrarPorPais, validarId, ctrl.eliminarTestimonio);

module.exports = router;
