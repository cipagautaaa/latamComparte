const ROLES = {
  SUPERADMIN: 'superadmin',
  ADMIN_PAIS: 'admin_pais',
  EDITOR:     'editor',
  VISITANTE:  'visitante',
};

// Roles de gestión exclusiva (portales, usuarios, configuración global)
const ROLES_ADMIN = [ROLES.SUPERADMIN, ROLES.ADMIN_PAIS];

// Roles que pueden crear/editar/publicar contenido (noticias, testimonios)
const ROLES_CONTENT = [ROLES.SUPERADMIN, ROLES.ADMIN_PAIS, ROLES.EDITOR];

module.exports = { ROLES, ROLES_ADMIN, ROLES_CONTENT };
