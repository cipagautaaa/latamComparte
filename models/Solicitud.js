const mongoose = require('mongoose');

const solicitudSchema = new mongoose.Schema({
  nombre: {
    type: String,
    required: [true, 'El nombre es requerido'],
    trim: true,
  },
  correo: {
    type: String,
    required: [true, 'El correo es requerido'],
    trim: true,
    lowercase: true,
  },
  telefono: {
    type: String,
    required: [true, 'El teléfono es requerido'],
    trim: true,
  },
  finalidad: {
    type: String,
    required: [true, 'La finalidad es requerida'],
    trim: true,
  },
  pais: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Pais',
    required: [true, 'El país es requerido'],
  },
  estado: {
    type: String,
    enum: ['pendiente', 'gestionada', 'respondida'],
    default: 'pendiente',
  },
  // fecha_creacion manual: no usamos timestamps:true para no tener
  // createdAt/updatedAt duplicados que nadie usa en este modelo.
  fecha_creacion: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Solicitud', solicitudSchema);
