const express = require('express');
const router  = express.Router();
const { estadisticasDashboard } = require('../controllers/dashboardController');
const { verificarToken, verificarRol, filtrarPorPais } = require('../middleware/auth');
const { ROLES_CONTENT } = require('../constants/roles');

// Solo roles de contenido/administración. El visitante tiene su propia vista pública.
router.get('/estadisticas', verificarToken, verificarRol(...ROLES_CONTENT), filtrarPorPais, estadisticasDashboard);

module.exports = router;
