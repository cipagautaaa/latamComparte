const mongoose = require('mongoose');

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
    enum: ['borrador', 'publicado', 'despublicado'],
    default: 'borrador',
  },
  fecha_creacion: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Testimonio', testimonioSchema);
