const mongoose = require('mongoose');

const paisSchema = new mongoose.Schema({
  nombre: {
    type: String,
    required: [true, 'El nombre del país es requerido'],
    enum: ['Colombia', 'Chile', 'Ecuador'],
    trim: true,
  },
  codigo: {
    type: String,
    required: true,
    enum: ['CO', 'CL', 'EC'],
    unique: true,
    trim: true,
    uppercase: true,
  },
  activo: {
    type: Boolean,
    default: true,
  },
}, { timestamps: true });

module.exports = mongoose.model('Pais', paisSchema);
