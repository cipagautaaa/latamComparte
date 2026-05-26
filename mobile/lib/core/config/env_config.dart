// Configuración por entorno usando --dart-define en tiempo de compilación
//
// Uso:
//   Emulador Android:   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
//   Dispositivo físico: flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000/api
//   Producción:         flutter build apk --dart-define=API_BASE_URL=https://api.tudominio.com/api
//
// Si no se pasa --dart-define, usa el valor por defecto (emulador Android).
class EnvConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
}
