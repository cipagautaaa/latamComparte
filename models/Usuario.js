const mongoose = require('mongoose');
const bcrypt   = require('bcryptjs');

const usuarioSchema = new mongoose.Schema({
  nombre: {
    type: String,
    required: [true, 'El nombre es requerido'],
    trim: true,
  },
  correo: {
    type: String,
    required: [true, 'El correo es requerido'],
    unique: true,
    lowercase: true,
    trim: true,
  },
  // El campo se llama password_hash para dejar claro que nunca se guarda en texto plano
  password_hash: {
    type: String,
    required: [true, 'La contraseña es requerida'],
  },
  rol: {
    type: String,
    enum: ['superadmin', 'admin_pais', 'editor', 'visitante'],
    default: 'editor',
  },
  // Solo aplica para admin_pais y editor; superadmin y visitante lo dejan en null
  pais_asignado: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Pais',
    default: null,
  },
  activo: {
    type: Boolean,
    default: true,
  },
}, { timestamps: true });

// Pre-save: hashea la contraseña solo si cambió.
// El isModified evita hashearlo de nuevo en updates que no tocan el password.
usuarioSchema.pre('save', async function () {
  if (!this.isModified('password_hash')) return;
  this.password_hash = await bcrypt.hash(this.password_hash, 12);
});

usuarioSchema.methods.compararPassword = async function (password) {
  return bcrypt.compare(password, this.password_hash);
};

// Nunca exponer el hash en respuestas JSON
usuarioSchema.set('toJSON', {
  transform: function (doc, ret) {
    delete ret.password_hash;
    return ret;
  },
});

module.exports = mongoose.model('Usuario', usuarioSchema);
