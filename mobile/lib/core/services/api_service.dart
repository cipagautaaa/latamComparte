import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../../models/models.dart';

/// Excepción tipada del servicio API.
/// Usar una clase propia en lugar de `throw String` o `throw Exception`
/// permite que los catch blocks sean más expresivos y el mensaje llegue
/// limpio a la UI sin el prefijo "Exception: ".
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static ApiService? _instance;
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Singleton: una sola instancia en toda la app para reutilizar el cliente HTTP
  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  // Callback que AuthProvider asigna al iniciar; se dispara si el servidor responde 401/403
  Function()? onForcedLogout;

  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Adjunta el token en cada request si existe en el storage seguro
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException e, handler) async {
        final status = e.response?.statusCode;
        final code   = e.response?.data?['code'];

        // 401 = token expirado o inválido; 403 PORTAL_SUSPENDED = portal desactivado.
        // En ambos casos borramos el token y forzamos logout para redirigir al login.
        if (status == 401 || (status == 403 && code == 'PORTAL_SUSPENDED')) {
          await _storage.delete(key: AppConstants.tokenKey);
          await _storage.delete(key: AppConstants.userKey);
          onForcedLogout?.call();
        }
        handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  /// Extrae el mensaje de error del body de la respuesta o devuelve uno genérico.
  String _extractMessage(DioException e) {
    return e.response?.data?['message'] as String? ?? 'Error de conexión. Intenta de nuevo.';
  }

  // ─── AUTH ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String correo, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {'correo': correo, 'password': password});
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  /// Valida el token guardado y devuelve los datos frescos del usuario
  Future<Map<String, dynamic>> getMe() async {
    try {
      final res = await _dio.get('/auth/me');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    // Limpiar siempre el storage local aunque el request falle
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  // ─── PAÍSES ───────────────────────────────────────────────────────────────
  Future<List<Pais>> getPaises() async {
    try {
      final res = await _dio.get('/paises');
      return _parsePaisesList(res.data);
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<List<Pais>> getPaisesPublico() async {
    try {
      final res = await _dio.get('/paises/publico');
      return _parsePaisesList(res.data);
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  List<Pais> _parsePaisesList(dynamic data) {
    final List raw = data is List ? data : (data['paises'] as List? ?? []);
    return raw.map((p) => Pais.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<void> actualizarEstadoPais(String id, bool activo) async {
    try {
      await _dio.patch('/paises/$id/estado', data: {'activo': activo});
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  // ─── SOLICITUDES ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSolicitudes({String? estado, String? pais, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': AppConstants.pageSize};
      if (estado != null) params['estado'] = estado;
      if (pais   != null) params['pais']   = pais;
      final res = await _dio.get('/solicitudes', queryParameters: params);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<Map<String, dynamic>> getSolicitud(String id) async {
    try {
      final res = await _dio.get('/solicitudes/$id');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<Map<String, dynamic>> actualizarEstadoSolicitud(String id, String estado) async {
    try {
      final res = await _dio.patch('/solicitudes/$id/estado', data: {'estado': estado});
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<void> eliminarSolicitud(String id) async {
    try {
      await _dio.delete('/solicitudes/$id');
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  /// Sin auth: endpoint público para el formulario de contacto
  Future<Map<String, dynamic>> crearSolicitudPublica(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/solicitudes', data: data);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  /// Solo para visitantes: devuelve las solicitudes que coinciden con su correo.
  /// Retorna lista tipada directamente para simplificar el código en los widgets.
  Future<List<Solicitud>> getMiSolicitud() async {
    try {
      final res = await _dio.get('/solicitudes/mi-solicitud');
      final List raw = res.data['solicitudes'] as List? ?? [];
      return raw.map((j) => Solicitud.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  // ─── TESTIMONIOS ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getTestimonios({String? estado, String? pais, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': AppConstants.pageSize};
      if (estado != null) params['estado'] = estado;
      if (pais   != null) params['pais']   = pais;
      final res = await _dio.get('/testimonios', queryParameters: params);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  /// Sin auth: para la vista del visitante. Retorna lista tipada directamente.
  Future<List<Testimonio>> getTestimoniosPublicos({String? pais}) async {
    try {
      final params = <String, dynamic>{};
      if (pais != null) params['pais'] = pais;
      final res = await _dio.get(
        '/testimonios/publico',
        queryParameters: params.isEmpty ? null : params,
      );
      final List raw = res.data as List;
      return raw.map((j) => Testimonio.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<Testimonio> getTestimonio(String id) async {
    try {
      final res = await _dio.get('/testimonios/$id');
      return Testimonio.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<Map<String, dynamic>> crearTestimonio(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/testimonios', data: data);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<Map<String, dynamic>> editarTestimonio(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/testimonios/$id', data: data);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<Map<String, dynamic>> cambiarEstadoTestimonio(String id, String estado) async {
    try {
      final res = await _dio.patch('/testimonios/$id/estado', data: {'estado': estado});
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<void> eliminarTestimonio(String id) async {
    try {
      await _dio.delete('/testimonios/$id');
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  // ─── NOTICIAS ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getNoticias({String? estado, String? pais, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': AppConstants.pageSize};
      if (estado != null) params['estado'] = estado;
      if (pais   != null) params['pais']   = pais;
      final res = await _dio.get('/noticias', queryParameters: params);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  /// Sin auth: para la vista del visitante. Retorna lista tipada directamente.
  Future<List<Noticia>> getNoticiasPublicas({String? pais}) async {
    try {
      final params = <String, dynamic>{};
      if (pais != null) params['pais'] = pais;
      final res = await _dio.get(
        '/noticias/publico',
        queryParameters: params.isEmpty ? null : params,
      );
      final List raw = res.data as List;
      return raw.map((j) => Noticia.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<Map<String, dynamic>> getNoticia(String id) async {
    try {
      final res = await _dio.get('/noticias/$id');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<Map<String, dynamic>> crearNoticia(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/noticias', data: data);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<Map<String, dynamic>> editarNoticia(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/noticias/$id', data: data);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<Map<String, dynamic>> cambiarEstadoNoticia(String id, String estado) async {
    try {
      final res = await _dio.patch('/noticias/$id/estado', data: {'estado': estado});
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<void> eliminarNoticia(String id) async {
    try {
      await _dio.delete('/noticias/$id');
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  // ─── DASHBOARD ────────────────────────────────────────────────────────────
  // Endpoint dedicado /api/dashboard/estadisticas (separado de /api/noticias
  // por principio de responsabilidad única — el dashboard no es una noticia).
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final res = await _dio.get('/dashboard/estadisticas');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }
}
