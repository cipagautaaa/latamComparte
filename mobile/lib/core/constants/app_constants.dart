import '../config/env_config.dart';

class AppConstants {
  // URL del backend — se configura con --dart-define=API_BASE_URL=... en tiempo de compilación
  // Ver mobile/lib/core/config/env_config.dart para instrucciones
  static String get baseUrl => EnvConfig.apiBaseUrl;

  // Timeout de peticiones
  static const int connectTimeout = 15000; // ms
  static const int receiveTimeout = 15000; // ms

  // Storage keys
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';

  // Paginación
  static const int pageSize = 20;

  // Roles
  static const String rolSuperadmin = 'superadmin';
  static const String rolAdminPais = 'admin_pais';
  static const String rolEditor = 'editor';
  static const String rolVisitante = 'visitante';

  // Estados solicitudes
  static const String estadoPendiente = 'pendiente';
  static const String estadoGestionada = 'gestionada';
  static const String estadoRespondida = 'respondida';

  // Estados contenido
  static const String estadoBorrador = 'borrador';
  static const String estadoPublicado = 'publicado';
  static const String estadoDespublicado = 'despublicado';
}
