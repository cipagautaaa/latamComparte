const mongoose = require('mongoose');
const { ESTADOS_TESTIMONIO } = require('../constants/estados');

const testimonioSchema = new mongoose.Schema({
  nombre: {
    type: String,
    required: [true, 'El nombre es requerido'],
    trim: true,
  },
  foto_url: {
    type: String,
    required: [true, 'La foto es requerida'],
  },
  testimonio: {
    type: String,
    required: [true, 'El texto del testimonio es requerido'],
    trim: true,
  },
  pais: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Pais',
    required: [true, 'El país es requerido'],
  },
  instagram_url: { type: String, default: null },
  facebook_url:  { type: String, default: null },
  estado: {
    type: String,
    enum: ESTADOS_TESTIMONIO,
    default: ESTADOS_TESTIMONIO[0], // 'borrador'
  },
}, {
  timestamps: { createdAt: 'fecha_creacion', updatedAt: 'fecha_actualizacion' },
});

module.exports = mongoose.model('Testimonio', testimonioSchema);
