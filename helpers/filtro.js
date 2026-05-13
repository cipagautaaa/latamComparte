const { Types } = require('mongoose');

// Arma el filtro de consulta según el contexto del usuario.
// paisFiltro viene del middleware y tiene prioridad; el query param es para superadmin.
const buildFiltro = (req) => {
  const filtro = {};
  if (req.paisFiltro)        filtro.pais   = req.paisFiltro;
  else if (req.query.pais)   filtro.pais   = req.query.pais;
  if (req.query.estado)      filtro.estado = req.query.estado;
  return filtro;
};

// Parseamos los parámetros de paginación con un tope de 100 para evitar
// que alguien mande ?limit=999999 y vacíe la BD en un solo request.
const MAX_LIMIT = 100;
const parsePaginacion = (query) => {
  const page  = Math.max(1, parseInt(query.page)  || 1);
  const limit = Math.min(MAX_LIMIT, Math.max(1, parseInt(query.limit) || 20));
  const skip  = (page - 1) * limit;
  return { page, limit, skip };
};

// Middleware: rechaza IDs que no sean un ObjectId válido de Mongo.
// Sin esto, Mongoose tira un CastError no controlado que el handler global
// convierte en 500, cuando debería ser un 400 claro.
const validarId = (req, res, next) => {
  if (!Types.ObjectId.isValid(req.params.id)) {
    return res.status(400).json({ message: 'ID no válido' });
  }
  next();
};

module.exports = { buildFiltro, parsePaginacion, validarId };
