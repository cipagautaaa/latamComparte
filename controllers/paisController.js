const Pais = require('../models/Pais');

const listarPaises = async (req, res) => {
  try {
    const paises = await Pais.find().sort({ nombre: 1 });
    res.json(paises);
  } catch (err) {
    res.status(500).json({ message: 'Error al obtener países' });
  }
};

const listarPaisesPublico = async (req, res) => {
  try {
    const paises = await Pais.find({ activo: true }).select('nombre codigo');
    res.json(paises);
  } catch (err) {
    res.status(500).json({ message: 'Error al obtener países' });
  }
};

const actualizarEstado = async (req, res) => {
  try {
    const pais = await Pais.findByIdAndUpdate(
      req.params.id,
      { activo: req.body.activo },
      { new: true }
    );
    if (!pais) return res.status(404).json({ message: 'País no encontrado' });
    res.json(pais);
  } catch (err) {
    res.status(500).json({ message: 'Error al actualizar país' });
  }
};

module.exports = { listarPaises, listarPaisesPublico, actualizarEstado };
