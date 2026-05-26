const jwt     = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const Usuario = require('../models/Usuario');
const { ROLES } = require('../constants/roles');

const loginValidation = [
  body('correo').isEmail().normalizeEmail().withMessage('Correo inválido'),
  body('password').notEmpty().withMessage('Contraseña requerida'),
];

const login = async (req, res) => {
  const errores = validationResult(req);
  if (!errores.isEmpty()) {
    return res.status(400).json({ message: errores.array()[0].msg });
  }

  try {
    const { correo, password } = req.body;

    // populate aquí para incluir el país en la respuesta y verificar si está activo
    const usuario = await Usuario.findOne({ correo }).populate('pais_asignado');

    // Mismo mensaje para usuario no encontrado y contraseña incorrecta — no dar pistas
    if (!usuario || !usuario.activo) {
      return res.status(401).json({ message: 'Credenciales incorrectas' });
    }

    const passwordValida = await usuario.compararPassword(password);
    if (!passwordValida) {
      return res.status(401).json({ message: 'Credenciales incorrectas' });
    }

    const sinRestriccionPortal = usuario.rol === ROLES.SUPERADMIN || usuario.rol === ROLES.VISITANTE;
    if (!sinRestriccionPortal && usuario.pais_asignado && !usuario.pais_asignado.activo) {
      return res.status(403).json({
        code: 'PORTAL_SUSPENDED',
        message: 'Portal suspendido. Contacta al superadministrador.',
      });
    }

    const token = jwt.sign(
      { id: usuario._id, rol: usuario.rol, pais_id: usuario.pais_asignado?._id || null },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({
      token,
      usuario: {
        id:           usuario._id,
        nombre:       usuario.nombre,
        correo:       usuario.correo,
        rol:          usuario.rol,
        pais_asignado: usuario.pais_asignado,
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error del servidor' });
  }
};

// El logout real lo hace el cliente borrando el token del storage.
// Este endpoint existe para registrar el evento si se necesita en el futuro.
const logout = (req, res) => {
  res.json({ message: 'Sesión cerrada exitosamente' });
};

// La app llama a este endpoint al iniciar para verificar que el token guardado sigue válido.
// verificarToken ya hizo la consulta a BD y populó req.usuario, así que no la repetimos.
const getMe = (req, res) => {
  res.json(req.usuario);
};

module.exports = { loginValidation, login, logout, getMe };
