import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../../models/models.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  Usuario?   _usuario;
  String?    _error;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthStatus get status  => _status;
  Usuario?   get usuario => _usuario;
  String?    get error   => _error;

  bool get isAuthenticated  => _status == AuthStatus.authenticated;
  bool get isSuperadmin     => _usuario?.rol == AppConstants.rolSuperadmin;
  bool get isAdminPais      => _usuario?.rol == AppConstants.rolAdminPais;
  bool get isEditor         => _usuario?.rol == AppConstants.rolEditor;
  bool get isVisitante      => _usuario?.rol == AppConstants.rolVisitante;

  // Verdadero cuando el usuario solo puede ver datos de su país asignado
  bool get puedeVerSoloPais => isAdminPais || isEditor;
  String? get paisAsignadoId => _usuario?.paisAsignado?.id;

  // Se llama una vez al arrancar la app para restaurar la sesión si había una guardada
  Future<void> init() async {
    _status = AuthStatus.loading;
    notifyListeners();

    // Le decimos al ApiService cómo debe reaccionar si el servidor rechaza el token
    ApiService.instance.onForcedLogout = () {
      _usuario = null;
      _status  = AuthStatus.unauthenticated;
      _error   = 'Portal suspendido. Contacta al superadministrador.';
      notifyListeners();
    };

    try {
      final token    = await _storage.read(key: AppConstants.tokenKey);
      final userData = await _storage.read(key: AppConstants.userKey);

      if (token != null && userData != null) {
        try {
          // Intentamos validar el token con el servidor para obtener datos frescos
          final meData = await ApiService.instance.getMe();
          _usuario = Usuario.fromJson(meData);
          _status  = AuthStatus.authenticated;
        } catch (_) {
          // Si falló la red pero el token sigue en storage, usamos los datos en caché.
          // Si el interceptor ya limpió el token (401/403), el storage estará vacío y mandamos a login.
          final tokenAun = await _storage.read(key: AppConstants.tokenKey);
          if (tokenAun != null) {
            _usuario = Usuario.fromJson(jsonDecode(userData));
            _status  = AuthStatus.authenticated;
          } else {
            _usuario = null;
            _status  = AuthStatus.unauthenticated;
          }
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String correo, String password) async {
    _status = AuthStatus.loading;
    _error  = null;
    notifyListeners();

    try {
      final data         = await ApiService.instance.login(correo, password);
      final authResponse = AuthResponse.fromJson(data);

      // Guardamos token y datos básicos para poder restaurar la sesión sin red
      await _storage.write(key: AppConstants.tokenKey, value: authResponse.token);
      await _storage.write(
        key: AppConstants.userKey,
        value: jsonEncode({
          '_id':          authResponse.usuario.id,
          'nombre':       authResponse.usuario.nombre,
          'correo':       authResponse.usuario.correo,
          'rol':          authResponse.usuario.rol,
          'pais_asignado': authResponse.usuario.paisAsignado?.toJson(),
        }),
      );

      _usuario = authResponse.usuario;
      _status  = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error  = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.instance.logout();
    _usuario = null;
    _status  = AuthStatus.unauthenticated;
    _error   = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Superadmin ve todos los países; los demás roles solo ven el suyo
  bool puedeVerPais(String? paisId) {
    if (_usuario == null) return false;
    if (isSuperadmin) return true;
    return _usuario?.paisAsignado?.id == paisId;
  }

  bool get puedeEliminar       => isSuperadmin || isAdminPais;
  bool puedeGestionarUsuarios() => isSuperadmin;
}
