const ROLES = {
  SUPERADMIN: 'superadmin',
  ADMIN_PAIS: 'admin_pais',
  EDITOR:     'editor',
  VISITANTE:  'visitante',
};

// Roles que pueden gestionar contenido de administración
const ROLES_ADMIN = [ROLES.SUPERADMIN, ROLES.ADMIN_PAIS];

module.exports = { ROLES, ROLES_ADMIN };
