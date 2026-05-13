const { body, validationResult } = require('express-validator');
const Testimonio = require('../models/Testimonio');
const { ESTADOS_TESTIMONIO }         = require('../constants/estados');
const { buildFiltro, parsePaginacion } = require('../helpers/filtro');

const crearTestimonioValidation = [
  body('nombre').notEmpty().withMessage('Nombre requerido'),
  body('foto_url').notEmpty().withMessage('Foto requerida'),
  body('testimonio').notEmpty().withMessage('Texto del testimonio requerido'),
  body('pais').notEmpty().withMessage('País requerido'),
];

const listarTestimonios = async (req, res) => {
  try {
    const filtro            = buildFiltro(req);
    const { page, limit, skip } = parsePaginacion(req.query);

    const [testimonios, total] = await Promise.all([
      Testimonio.find(filtro)
        .populate('pais', 'nombre codigo')
        .sort({ fecha_creacion: -1 })
        .skip(skip)
        .limit(limit),
      Testimonio.countDocuments(filtro),
    ]);

    res.json({ testimonios, total, page, totalPages: Math.ceil(total / limit) });
  } catch (err) {
    res.status(500).json({ message: 'Error al obtener testimonios' });
  }
};

// Sin auth: lo usan la vista pública y la app del visitante
const listarTestimoniosPublico = async (req, res) => {
  try {
    const filtro = { estado: 'publicado' };
    if (req.query.pais) filtro.pais = req.query.pais;

    const testimonios = await Testimonio.find(filtro)
      .populate('pais', 'nombre codigo')
      .sort({ fecha_creacion: -1 });

    res.json(testimonios);
  } catch (err) {
    res.status(500).json({ message: 'Error al obtener testimonios' });
  }
};

const detalleTestimonio = async (req, res) => {
  try {
    const testimonio = await Testimonio.findById(req.params.id).populate('pais', 'nombre codigo');
    if (!testimonio) return res.status(404).json({ message: 'Testimonio no encontrado' });

    if (req.paisFiltro && testimonio.pais._id.toString() !== req.paisFiltro.toString()) {
      return res.status(403).json({ message: 'Acceso denegado' });
    }

    res.json(testimonio);
  } catch (err) {
    res.status(500).json({ message: 'Error al obtener testimonio' });
  }
};

const crearTestimonio = async (req, res) => {
  const errores = validationResult(req);
  if (!errores.isEmpty()) {
    return res.status(400).json({ message: errores.array()[0].msg });
  }

  try {
    const { nombre, foto_url, testimonio, pais, instagram_url, facebook_url, estado } = req.body;
    const paisFinal = req.paisFiltro || pais;

    const nuevo = await Testimonio.create({
      nombre, foto_url, testimonio,
      pais: paisFinal,
      instagram_url: instagram_url || null,
      facebook_url:  facebook_url  || null,
      estado: estado || 'borrador',
    });

    const populated = await nuevo.populate('pais', 'nombre codigo');
    res.status(201).json(populated);
  } catch (err) {
    res.status(500).json({ message: 'Error al crear testimonio' });
  }
};

const editarTestimonio = async (req, res) => {
  try {
    const testimonio = await Testimonio.findById(req.params.id).populate('pais');
    if (!testimonio) return res.status(404).json({ message: 'Testimonio no encontrado' });

    if (req.paisFiltro && testimonio.pais._id.toString() !== req.paisFiltro.toString()) {
      return res.status(403).json({ message: 'Acceso denegado' });
    }

    const camposPermitidos = ['nombre', 'foto_url', 'testimonio', 'instagram_url', 'facebook_url', 'estado'];
    camposPermitidos.forEach((campo) => {
      if (req.body[campo] !== undefined) testimonio[campo] = req.body[campo];
    });

    await testimonio.save();
    const populated = await testimonio.populate('pais', 'nombre codigo');
    res.json(populated);
  } catch (err) {
    res.status(500).json({ message: 'Error al actualizar testimonio' });
  }
};

const cambiarEstado = async (req, res) => {
  try {
    const { estado } = req.body;
    if (!ESTADOS_TESTIMONIO.includes(estado)) {
      return res.status(400).json({ message: 'Estado no válido' });
    }

    const testimonio = await Testimonio.findById(req.params.id).populate('pais');
    if (!testimonio) return res.status(404).json({ message: 'Testimonio no encontrado' });

    if (req.paisFiltro && testimonio.pais._id.toString() !== req.paisFiltro.toString()) {
      return res.status(403).json({ message: 'Acceso denegado' });
    }

    testimonio.estado = estado;
    await testimonio.save();
    res.json(testimonio);
  } catch (err) {
    res.status(500).json({ message: 'Error al cambiar estado' });
  }
};

const eliminarTestimonio = async (req, res) => {
  try {
    const testimonio = await Testimonio.findById(req.params.id).populate('pais');
    if (!testimonio) return res.status(404).json({ message: 'Testimonio no encontrado' });

    if (req.paisFiltro && testimonio.pais._id.toString() !== req.paisFiltro.toString()) {
      return res.status(403).json({ message: 'Acceso denegado' });
    }

    await testimonio.deleteOne();
    res.json({ message: 'Testimonio eliminado exitosamente' });
  } catch (err) {
    res.status(500).json({ message: 'Error al eliminar testimonio' });
  }
};

module.exports = {
  crearTestimonioValidation,
  listarTestimonios,
  listarTestimoniosPublico,
  detalleTestimonio,
  crearTestimonio,
  editarTestimonio,
  cambiarEstado,
  eliminarTestimonio,
};
