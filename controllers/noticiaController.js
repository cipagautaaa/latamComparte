const { body, validationResult } = require('express-validator');
const Noticia    = require('../models/Noticia');
const Testimonio = require('../models/Testimonio');
const Solicitud  = require('../models/Solicitud');
const { ESTADOS_CONTENIDO }     = require('../constants/estados');
const { buildFiltro, parsePaginacion } = require('../helpers/filtro');

const crearNoticiaValidation = [
  body('titulo').notEmpty().withMessage('Título requerido'),
  body('resumen').notEmpty().withMessage('Resumen requerido'),
  body('contenido').notEmpty().withMessage('Contenido requerido'),
  body('autor').notEmpty().withMessage('Autor requerido'),
  body('pais').notEmpty().withMessage('País requerido'),
];

const listarNoticias = async (req, res) => {
  try {
    const filtro            = buildFiltro(req);
    const { page, limit, skip } = parsePaginacion(req.query);

    const [noticias, total] = await Promise.all([
      Noticia.find(filtro)
        .populate('pais', 'nombre codigo')
        .sort({ fecha_creacion: -1 })
        .skip(skip)
        .limit(limit),
      Noticia.countDocuments(filtro),
    ]);

    res.json({ noticias, total, page, totalPages: Math.ceil(total / limit) });
  } catch (err) {
    res.status(500).json({ message: 'Error al obtener noticias' });
  }
};

// Sin auth: visitante y formulario público las consumen
const listarNoticiasPublico = async (req, res) => {
  try {
    const filtro = { estado: 'publicado' };
    if (req.query.pais) filtro.pais = req.query.pais;

    const noticias = await Noticia.find(filtro)
      .populate('pais', 'nombre codigo')
      .sort({ fecha_creacion: -1 });

    res.json(noticias);
  } catch (err) {
    res.status(500).json({ message: 'Error al obtener noticias' });
  }
};

// Reúne conteos de noticias, testimonios y solicitudes en una llamada
// para evitar que el dashboard haga tres requests al cargar
const estadisticasDashboard = async (req, res) => {
  try {
    const filtro = req.paisFiltro ? { pais: req.paisFiltro } : {};

    const [
      totalNoticias,
      noticiasActivas,
      totalTestimonios,
      testimoniosPublicados,
      solicitudesPendientes,
    ] = await Promise.all([
      Noticia.countDocuments(filtro),
      Noticia.countDocuments({ ...filtro, estado: 'publicado' }),
      Testimonio.countDocuments(filtro),
      Testimonio.countDocuments({ ...filtro, estado: 'publicado' }),
      Solicitud.countDocuments({ ...filtro, estado: 'pendiente' }),
    ]);

    res.json({
      noticias:    { total: totalNoticias,    activas:    noticiasActivas },
      testimonios: { total: totalTestimonios, publicados: testimoniosPublicados },
      solicitudes: { pendientes: solicitudesPendientes },
    });
  } catch (err) {
    res.status(500).json({ message: 'Error al obtener estadísticas' });
  }
};

const detalleNoticia = async (req, res) => {
  try {
    const noticia = await Noticia.findById(req.params.id).populate('pais', 'nombre codigo');
    if (!noticia) return res.status(404).json({ message: 'Noticia no encontrada' });

    if (req.paisFiltro && noticia.pais._id.toString() !== req.paisFiltro.toString()) {
      return res.status(403).json({ message: 'Acceso denegado' });
    }

    res.json(noticia);
  } catch (err) {
    res.status(500).json({ message: 'Error al obtener noticia' });
  }
};

const crearNoticia = async (req, res) => {
  const errores = validationResult(req);
  if (!errores.isEmpty()) {
    return res.status(400).json({ message: errores.array()[0].msg });
  }

  try {
    const { titulo, resumen, contenido, autor, imagen_url, pais, estado } = req.body;
    const paisFinal = req.paisFiltro || pais;

    const noticia = await Noticia.create({
      titulo, resumen, contenido, autor,
      imagen_url: imagen_url || null,
      pais: paisFinal,
      estado: estado || 'borrador',
    });

    const populated = await noticia.populate('pais', 'nombre codigo');
    res.status(201).json(populated);
  } catch (err) {
    res.status(500).json({ message: 'Error al crear noticia' });
  }
};

const editarNoticia = async (req, res) => {
  try {
    const noticia = await Noticia.findById(req.params.id).populate('pais');
    if (!noticia) return res.status(404).json({ message: 'Noticia no encontrada' });

    if (req.paisFiltro && noticia.pais._id.toString() !== req.paisFiltro.toString()) {
      return res.status(403).json({ message: 'Acceso denegado' });
    }

    // Lista explícita para que no se pueda sobreescribir el _id ni el país
    const camposPermitidos = ['titulo', 'resumen', 'contenido', 'autor', 'imagen_url', 'estado'];
    camposPermitidos.forEach((campo) => {
      if (req.body[campo] !== undefined) noticia[campo] = req.body[campo];
    });

    await noticia.save();
    const populated = await noticia.populate('pais', 'nombre codigo');
    res.json(populated);
  } catch (err) {
    res.status(500).json({ message: 'Error al actualizar noticia' });
  }
};

const cambiarEstado = async (req, res) => {
  try {
    const { estado } = req.body;
    if (!ESTADOS_CONTENIDO.includes(estado)) {
      return res.status(400).json({ message: 'Estado no válido' });
    }

    const noticia = await Noticia.findById(req.params.id).populate('pais');
    if (!noticia) return res.status(404).json({ message: 'Noticia no encontrada' });

    if (req.paisFiltro && noticia.pais._id.toString() !== req.paisFiltro.toString()) {
      return res.status(403).json({ message: 'Acceso denegado' });
    }

    noticia.estado = estado;
    await noticia.save();
    res.json(noticia);
  } catch (err) {
    res.status(500).json({ message: 'Error al cambiar estado' });
  }
};

const eliminarNoticia = async (req, res) => {
  try {
    const noticia = await Noticia.findById(req.params.id).populate('pais');
    if (!noticia) return res.status(404).json({ message: 'Noticia no encontrada' });

    if (req.paisFiltro && noticia.pais._id.toString() !== req.paisFiltro.toString()) {
      return res.status(403).json({ message: 'Acceso denegado' });
    }

    await noticia.deleteOne();
    res.json({ message: 'Noticia eliminada exitosamente' });
  } catch (err) {
    res.status(500).json({ message: 'Error al eliminar noticia' });
  }
};

module.exports = {
  crearNoticiaValidation,
  listarNoticias,
  listarNoticiasPublico,
  estadisticasDashboard,
  detalleNoticia,
  crearNoticia,
  editarNoticia,
  cambiarEstado,
  eliminarNoticia,
};
