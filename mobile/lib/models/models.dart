// ─── Modelo Pais ─────────────────────────────────────────────────────────────
class Pais {
  final String id;
  final String nombre;
  final String codigo;
  final bool activo;

  Pais({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.activo,
  });

  factory Pais.fromJson(Map<String, dynamic> json) => Pais(
    id: json['_id'] ?? '',
    nombre: json['nombre'] ?? '',
    codigo: json['codigo'] ?? '',
    activo: json['activo'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'nombre': nombre,
    'codigo': codigo,
    'activo': activo,
  };
}

// ─── Modelo Usuario ───────────────────────────────────────────────────────────
class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final Pais? paisAsignado;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.paisAsignado,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['_id'] ?? json['id'] ?? '',
    nombre: json['nombre'] ?? '',
    correo: json['correo'] ?? '',
    rol: json['rol'] ?? 'editor',
    paisAsignado: json['pais_asignado'] != null
        ? Pais.fromJson(json['pais_asignado'])
        : null,
  );

  String? get paisNombre => paisAsignado?.nombre;
  String? get paisCodigo => paisAsignado?.codigo;
  bool get esSuperadmin => rol == 'superadmin';
  bool get esAdminPais => rol == 'admin_pais';
  bool get esEditor => rol == 'editor';
}

// ─── Modelo Solicitud ────────────────────────────────────────────────────────
class Solicitud {
  final String id;
  final String nombre;
  final String correo;
  final String telefono;
  final String finalidad;
  final Pais? pais;
  final String estado;
  final DateTime? fechaCreacion;

  Solicitud({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.finalidad,
    this.pais,
    required this.estado,
    this.fechaCreacion,
  });

  factory Solicitud.fromJson(Map<String, dynamic> json) => Solicitud(
    id: json['_id'] ?? '',
    nombre: json['nombre'] ?? '',
    correo: json['correo'] ?? '',
    telefono: json['telefono'] ?? '',
    finalidad: json['finalidad'] ?? '',
    pais: json['pais'] != null ? Pais.fromJson(json['pais']) : null,
    estado: json['estado'] ?? 'pendiente',
    fechaCreacion: json['fecha_creacion'] != null
        ? DateTime.tryParse(json['fecha_creacion'])
        : null,
  );
}

// ─── Modelo Testimonio ────────────────────────────────────────────────────────
class Testimonio {
  final String id;
  final String nombre;
  final String fotoUrl;
  final String testimonio;
  final Pais? pais;
  final String? instagramUrl;
  final String? facebookUrl;
  final String estado;
  final DateTime? fechaCreacion;

  Testimonio({
    required this.id,
    required this.nombre,
    required this.fotoUrl,
    required this.testimonio,
    this.pais,
    this.instagramUrl,
    this.facebookUrl,
    required this.estado,
    this.fechaCreacion,
  });

  String? get paisId => pais?.id;

  factory Testimonio.fromJson(Map<String, dynamic> json) => Testimonio(
    id: json['_id'] ?? '',
    nombre: json['nombre'] ?? '',
    fotoUrl: json['foto_url'] ?? '',
    testimonio: json['testimonio'] ?? '',
    pais: json['pais'] != null ? Pais.fromJson(json['pais']) : null,
    instagramUrl: json['instagram_url'],
    facebookUrl: json['facebook_url'],
    estado: json['estado'] ?? 'borrador',
    fechaCreacion: json['fecha_creacion'] != null
        ? DateTime.tryParse(json['fecha_creacion'])
        : null,
  );
}

// ─── Modelo Noticia ───────────────────────────────────────────────────────────
class Noticia {
  final String id;
  final String titulo;
  final String resumen;
  final String contenido;
  final String autor;
  final String? imagenUrl;
  final Pais? pais;
  final String estado;
  final DateTime? fechaCreacion;

  Noticia({
    required this.id,
    required this.titulo,
    required this.resumen,
    required this.contenido,
    required this.autor,
    this.imagenUrl,
    this.pais,
    required this.estado,
    this.fechaCreacion,
  });

  factory Noticia.fromJson(Map<String, dynamic> json) => Noticia(
    id: json['_id'] ?? '',
    titulo: json['titulo'] ?? '',
    resumen: json['resumen'] ?? '',
    contenido: json['contenido'] ?? '',
    autor: json['autor'] ?? '',
    imagenUrl: json['imagen_url'],
    pais: json['pais'] != null ? Pais.fromJson(json['pais']) : null,
    estado: json['estado'] ?? 'borrador',
    fechaCreacion: json['fecha_creacion'] != null
        ? DateTime.tryParse(json['fecha_creacion'])
        : null,
  );
}

// ─── Modelo AuthResponse ──────────────────────────────────────────────────────
class AuthResponse {
  final String token;
  final Usuario usuario;

  AuthResponse({required this.token, required this.usuario});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    token: json['token'] ?? '',
    usuario: Usuario.fromJson(json['usuario']),
  );
}

// ─── Modelo PaginatedResponse ─────────────────────────────────────────────────
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int totalPages;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
  });
}

// ─── Modelo DashboardStats ────────────────────────────────────────────────────
class DashboardStats {
  final int noticiasTotal;
  final int noticiasActivas;
  final int testimoniosTotal;
  final int testimoniosPublicados;
  final int solicitudesPendientes;

  DashboardStats({
    required this.noticiasTotal,
    required this.noticiasActivas,
    required this.testimoniosTotal,
    required this.testimoniosPublicados,
    required this.solicitudesPendientes,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    noticiasTotal: json['noticias']?['total'] ?? 0,
    noticiasActivas: json['noticias']?['activas'] ?? 0,
    testimoniosTotal: json['testimonios']?['total'] ?? 0,
    testimoniosPublicados: json['testimonios']?['publicados'] ?? 0,
    solicitudesPendientes: json['solicitudes']?['pendientes'] ?? 0,
  );
}
