const { body, validationResult } = require('express-validator');
const Noticia    = require('../models/Noticia');
const { ESTADOS_CONTENIDO }               = require('../constants/estados');
const { buildFiltro, parsePaginacion, verificarAccesoPais } = require('../helpers/filtro');

// Límite de seguridad para endpoints públicos (sin paginación explícita)
const LIMITE_PUBLICO = 50;

const crearNoticiaValidation = [
  body('titulo').notEmpty().withMessage('Título requerido').trim(),
  body('resumen').notEmpty().withMessage('Resumen requerido').trim(),
  body('contenido').notEmpty().withMessage('Contenido requerido').trim(),
  body('autor').notEmpty().withMessage('Autor requerido').trim(),
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

// Sin auth: visitante y formulario público las consumen.
// LIMITE_PUBLICO evita que un solo request vacíe la colección completa.
const listarNoticiasPublico = async (req, res) => {
  try {
    const filtro = { estado: 'publicado' };
    if (req.query.pais) filtro.pais = req.query.pais;

    const noticias = await Noticia.find(filtro)
      .populate('pais', 'nombre codigo')
      .sort({ fecha_creacion: -1 })
      .limit(LIMITE_PUBLICO);

    res.json(noticias);
  } catch (err) {
    res.status(500).json({ message: 'Error al obtener noticias' });
  }
};

const detalleNoticia = async (req, res) => {
  try {
    const noticia = await Noticia.findById(req.params.id).populate('pais', 'nombre codigo');
    if (!noticia) return res.status(404).json({ message: 'Noticia no encontrada' });

    if (!verificarAccesoPais(req, res, noticia.pais?._id)) return;

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

    // Los editores/admins de un país no pueden asignar la noticia a otro país.
    const paisFinal = req.paisFiltro || pais;
    if (!paisFinal) return res.status(400).json({ message: 'País requerido' });

    // Validar estado si se provee
    if (estado && !ESTADOS_CONTENIDO.includes(estado)) {
      return res.status(400).json({ message: `Estado no válido. Valores permitidos: ${ESTADOS_CONTENIDO.join(', ')}` });
    }

    const noticia = await Noticia.create({
      titulo, resumen, contenido, autor,
      imagen_url: imagen_url || null,
      pais: paisFinal,
      estado: estado || 'borrador',
    });

    const populated = await noticia.populate('pais', 'nombre codigo');
    res.status(201).json(populated);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error al crear noticia' });
  }
};

const editarNoticia = async (req, res) => {
  try {
    const noticia = await Noticia.findById(req.params.id).populate('pais');
    if (!noticia) return res.status(404).json({ message: 'Noticia no encontrada' });

    if (!verificarAccesoPais(req, res, noticia.pais?._id)) return;

    // Lista explícita para evitar sobrescribir campos protegidos (_id, pais, __v)
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
      return res.status(400).json({ message: `Estado no válido. Valores permitidos: ${ESTADOS_CONTENIDO.join(', ')}` });
    }

    const noticia = await Noticia.findById(req.params.id).populate('pais');
    if (!noticia) return res.status(404).json({ message: 'Noticia no encontrada' });

    if (!verificarAccesoPais(req, res, noticia.pais?._id)) return;

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

    if (!verificarAccesoPais(req, res, noticia.pais?._id)) return;

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
  detalleNoticia,
  crearNoticia,
  editarNoticia,
  cambiarEstado,
  eliminarNoticia,
};
