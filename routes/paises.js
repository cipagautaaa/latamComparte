const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/paisController');
const { verificarToken, verificarRol } = require('../middleware/auth');
const { ROLES } = require('../constants/roles');

router.get('/', verificarToken, verificarRol(ROLES.SUPERADMIN), ctrl.listarPaises);
router.get('/publico', ctrl.listarPaisesPublico);
router.patch('/:id/estado', verificarToken, verificarRol(ROLES.SUPERADMIN), ctrl.actualizarEstado);

module.exports = router;
