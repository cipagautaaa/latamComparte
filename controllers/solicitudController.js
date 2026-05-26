const { Types }  = require('mongoose');
const { body, validationResult } = require('express-validator');
const Solicitud = require('../models/Solicitud');
const Pais      = require('../models/Pais');
const { ESTADOS_SOLICITUD }  = require('../constants/estados');
const { parsePaginacion, verificarAccesoPais } = require('../helpers/filtro');

const crearSolicitudValidation = [
  body('nombre').notEmpty().withMessage('Nombre requerido').trim(),
  body('correo').isEmail().normalizeEmail().withMessage('Correo inválido'),
  body('telefono').notEmpty().withMessage('Teléfono requerido').trim(),
  body('finalidad').notEmpty().withMessage('Finalidad requerida').trim(),
  body('pais').notEmpty().withMessage('País requerido'),
];

const crearSolicitud = async (req, res) => {
  const errores = validationResult(req);
  if (!errores.isEmpty()) {
    return res.status(400).json({ message: errores.array()[0].msg });
  }

  try {
    const { nombre, correo, telefono, finalidad, pais } = req.body;

    // Determinamos si el valor es un ObjectId de Mongo o un código ISO de 2 letras.
    // Usamos Types.ObjectId.isValid() en lugar de comprobar la longitud del string,
    // que es frágil (un código de 3 letras pasaría la validación sin ser un ObjectId).
    const paisDoc = Types.ObjectId.isValid(pais)
      ? await Pais.findById(pais)
      : await Pais.findOne({ codigo: pais.toUpperCase() });

    if (!paisDoc) return res.status(400).json({ message: 'País no válido' });

    const solicitud = await Solicitud.create({ nombre, correo, telefono, finalidad, pais: paisDoc._id });
    res.status(201).json({ message: 'Solicitud enviada exitosamente', solicitud });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error al crear solicitud' });
  }
};

const listarSolicitudes = async (req, res) => {
  try {
    const filtro = {};
    if (req.paisFiltro)      filtro.pais   = req.paisFiltro;
    else if (req.query.pais) filtro.pais   = req.query.pais;
    if (req.query.estado)    filtro.estado = req.query.estado;

    const { page, limit, skip } = parsePaginacion(req.query);

    const [solicitudes, total] = await Promise.all([
      Solicitud.find(filtro)
        .populate('pais', 'nombre codigo')
        .sort({ fecha_creacion: -1 })
        .skip(skip)
        .limit(limit),
      Solicitud.countDocuments(filtro),
    ]);

    res.json({ solicitudes, total, page, totalPages: Math.ceil(total / limit) });
  } catch (err) {
    res.status(500).json({ message: 'Error al obtener solicitudes' });
  }
};

const detalleSolicitud = async (req, res) => {
  try {
    const solicitud = await Solicitud.findById(req.params.id).populate('pais', 'nombre codigo');
    if (!solicitud) return res.status(404).json({ message: 'Solicitud no encontrada' });

    // Aunque filtrarPorPais bloquea el listado, se valida también en el detalle
    // para evitar que alguien acceda directamente al ID de otra región.
    if (!verificarAccesoPais(req, res, solicitud.pais?._id)) return;

    res.json(solicitud);
  } catch (err) {
    res.status(500).json({ message: 'Error al obtener solicitud' });
  }
};

const actualizarEstado = async (req, res) => {
  try {
    const { estado } = req.body;
    if (!ESTADOS_SOLICITUD.includes(estado)) {
      return res.status(400).json({ message: `Estado no válido. Valores permitidos: ${ESTADOS_SOLICITUD.join(', ')}` });
    }

    const solicitud = await Solicitud.findById(req.params.id).populate('pais');
    if (!solicitud) return res.status(404).json({ message: 'Solicitud no encontrada' });

    if (!verificarAccesoPais(req, res, solicitud.pais?._id)) return;

    solicitud.estado = estado;
    await solicitud.save();
    res.json(solicitud);
  } catch (err) {
    res.status(500).json({ message: 'Error al actualizar estado' });
  }
};

const eliminarSolicitud = async (req, res) => {
  try {
    const solicitud = await Solicitud.findById(req.params.id).populate('pais');
    if (!solicitud) return res.status(404).json({ message: 'Solicitud no encontrada' });

    if (!verificarAccesoPais(req, res, solicitud.pais?._id)) return;

    await solicitud.deleteOne();
    res.json({ message: 'Solicitud eliminada exitosamente' });
  } catch (err) {
    res.status(500).json({ message: 'Error al eliminar solicitud' });
  }
};

const estadisticasResumen = async (req, res) => {
  try {
    const filtro = req.paisFiltro ? { pais: req.paisFiltro } : {};

    const [stats, pendientes] = await Promise.all([
      Solicitud.aggregate([
        { $match: filtro },
        { $group: { _id: { pais: '$pais', estado: '$estado' }, count: { $sum: 1 } } },
        { $lookup: { from: Pais.collection.name, localField: '_id.pais', foreignField: '_id', as: 'paisInfo' } },
      ]),
      Solicitud.countDocuments({ ...filtro, estado: 'pendiente' }),
    ]);

    res.json({ stats, pendientes });
  } catch (err) {
    res.status(500).json({ message: 'Error al obtener estadísticas' });
  }
};

// Solo para visitantes: busca por el correo del usuario autenticado
const miSolicitud = async (req, res) => {
  try {
    const solicitudes = await Solicitud.find({ correo: req.usuario.correo })
      .populate('pais', 'nombre codigo')
      .sort({ fecha_creacion: -1 });

    res.json({ solicitudes });
  } catch (err) {
    res.status(500).json({ message: 'Error al obtener solicitudes' });
  }
};

module.exports = {
  crearSolicitudValidation,
  crearSolicitud,
  listarSolicitudes,
  detalleSolicitud,
  actualizarEstado,
  eliminarSolicitud,
  estadisticasResumen,
  miSolicitud,
};
