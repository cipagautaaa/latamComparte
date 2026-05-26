const express = require('express');
const router = express.Router();
const { loginValidation, login, logout, getMe } = require('../controllers/authController');
const { verificarToken } = require('../middleware/auth');

router.post('/login', loginValidation, login);
router.post('/logout', verificarToken, logout);
router.get('/me', verificarToken, getMe);

module.exports = router;
