const mongoose = require('mongoose');

const noticiaSchema = new mongoose.Schema({
  titulo: {
    type: String,
    required: [true, 'El título es requerido'],
    trim: true,
  },
  resumen: {
    type: String,
    required: [true, 'El resumen es requerido'],
    trim: true,
  },
  contenido: {
    type: String,
    required: [true, 'El contenido es requerido'],
    trim: true,
  },
  autor: {
    type: String,
    required: [true, 'El autor es requerido'],
    trim: true,
  },
  imagen_url: { type: String, default: null },
  pais: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Pais',
    required: [true, 'El país es requerido'],
  },
  estado: {
    type: String,
    enum: ['borrador', 'publicado'],
    default: 'borrador',
  },
  fecha_creacion: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Noticia', noticiaSchema);
