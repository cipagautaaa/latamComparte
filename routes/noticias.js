const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/noticiaController');
const { verificarToken, verificarRol, filtrarPorPais } = require('../middleware/auth');
const { ROLES_ADMIN, ROLES_CONTENT } = require('../constants/roles');
const { validarId } = require('../helpers/filtro');

// ─── Público (sin autenticación) ─────────────────────────────────────────────
router.get('/publico', ctrl.listarNoticiasPublico);

// ─── Protegido — solo roles de contenido (superadmin, admin_pais, editor) ───
// El visitante usa los endpoints /publico, no el CRUD administrativo.
router.get('/',             verificarToken, verificarRol(...ROLES_CONTENT), filtrarPorPais, ctrl.listarNoticias);
router.get('/:id',          verificarToken, verificarRol(...ROLES_CONTENT), filtrarPorPais, validarId, ctrl.detalleNoticia);
router.post('/',            verificarToken, verificarRol(...ROLES_CONTENT), filtrarPorPais, ctrl.crearNoticiaValidation, ctrl.crearNoticia);
router.put('/:id',          verificarToken, verificarRol(...ROLES_CONTENT), filtrarPorPais, validarId, ctrl.editarNoticia);
router.patch('/:id/estado', verificarToken, verificarRol(...ROLES_CONTENT), filtrarPorPais, validarId, ctrl.cambiarEstado);

// Eliminar es una operación destructiva: solo admin_pais y superadmin
router.delete('/:id',       verificarToken, verificarRol(...ROLES_ADMIN),   filtrarPorPais, validarId, ctrl.eliminarNoticia);

module.exports = router;
