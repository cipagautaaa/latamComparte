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
  const { activo } = req.body;

  // Validar que el campo sea estrictamente booleano para evitar coerciones inesperadas.
  // JSON envía true/false; una cadena "false" sería truthy sin esta comprobación.
  if (typeof activo !== 'boolean') {
    return res.status(400).json({ message: 'El campo "activo" debe ser un booleano' });
  }

  try {
    const pais = await Pais.findByIdAndUpdate(
      req.params.id,
      { activo },
      { new: true, runValidators: true }
    );
    if (!pais) return res.status(404).json({ message: 'País no encontrado' });
    res.json(pais);
  } catch (err) {
    res.status(500).json({ message: 'Error al actualizar país' });
  }
};

module.exports = { listarPaises, listarPaisesPublico, actualizarEstado };
