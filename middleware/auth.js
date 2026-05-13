const jwt    = require('jsonwebtoken');
const Usuario = require('../models/Usuario');
const { ROLES } = require('../constants/roles');

const verificarToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Token no proporcionado' });
    }

    const token   = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Siempre consultar la BD para detectar usuarios desactivados aunque el token sea válido
    const usuario = await Usuario.findById(decoded.id).populate('pais_asignado');
    if (!usuario || !usuario.activo) {
      return res.status(401).json({ message: 'Token inválido o usuario inactivo' });
    }

    // El visitante no tiene portal asignado y el superadmin puede activar/desactivar portales,
    // así que ninguno de los dos aplica a esta verificación.
    const sinRestriccionPortal = usuario.rol === ROLES.SUPERADMIN || usuario.rol === ROLES.VISITANTE;
    if (!sinRestriccionPortal && usuario.pais_asignado && !usuario.pais_asignado.activo) {
      return res.status(403).json({
        code: 'PORTAL_SUSPENDED',
        message: 'Portal suspendido. Contacta al superadministrador.',
      });
    }

    req.usuario = usuario;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Token expirado', expired: true });
    }
    return res.status(401).json({ message: 'Token inválido' });
  }
};

const verificarRol = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.usuario.rol)) {
      return res.status(403).json({ message: 'Acceso denegado: permisos insuficientes' });
    }
    next();
  };
};

// Restringe los datos al país del usuario para admin_pais y editor.
// Si req.paisFiltro queda definido, los controladores lo usan para filtrar consultas.
const filtrarPorPais = (req, res, next) => {
  const { rol } = req.usuario;
  if (rol === ROLES.ADMIN_PAIS || rol === ROLES.EDITOR) {
    req.paisFiltro = req.usuario.pais_asignado?._id;
    if (!req.paisFiltro) {
      return res.status(403).json({ message: 'Usuario sin país asignado' });
    }
  }
  next();
};

module.exports = { verificarToken, verificarRol, filtrarPorPais };
