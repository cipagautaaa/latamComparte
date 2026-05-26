import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_provider.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/noticias/noticias_screen.dart';
import '../../screens/noticias/formulario_noticia_screen.dart';
import '../../screens/testimonios/testimonios_screen.dart';
import '../../screens/testimonios/formulario_testimonio_screen.dart';
import '../../screens/solicitudes/solicitudes_screen.dart';
import '../../screens/solicitudes/detalle_solicitud_screen.dart';
import '../../screens/paises/paises_screen.dart';
import '../../screens/perfil/perfil_screen.dart';
import '../../screens/public/formulario_contacto_screen.dart';
import '../../screens/visitante/visitante_dashboard_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      // GoRouter recalcula los redirects cada vez que authProvider notifica cambios
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoading       = authProvider.status == AuthStatus.initial ||
                                authProvider.status == AuthStatus.loading;
        final location        = state.uri.path;

        // Splash y contacto no requieren auth
        if (location == '/splash' || location == '/contacto') return null;

        // Mientras carga la sesión, mostrar splash
        if (isLoading) return '/splash';

        // Sin sesión → login (excepto si ya está ahí)
        if (!isAuthenticated && location != '/login') return '/login';

        // Con sesión en la pantalla de login → redirigir según rol
        if (isAuthenticated && location == '/login') {
          return authProvider.isVisitante ? '/visitante' : '/dashboard';
        }

        // Evitar que un visitante acceda a rutas de administración navegando directo a la URL
        if (isAuthenticated && authProvider.isVisitante) {
          const rutasAdmin = ['/dashboard', '/noticias', '/testimonios', '/solicitudes', '/paises'];
          if (rutasAdmin.any((r) => location.startsWith(r))) return '/visitante';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/splash',   builder: (ctx, state) => const SplashScreen()),
        GoRoute(path: '/login',    builder: (ctx, state) => const LoginScreen()),
        GoRoute(path: '/contacto', builder: (ctx, state) => const FormularioContactoScreen()),

        // ── Administración ────────────────────────────────────────────────────
        GoRoute(path: '/dashboard', builder: (ctx, state) => const DashboardScreen()),
        GoRoute(
          path: '/noticias',
          builder: (ctx, state) => const NoticiasScreen(),
          routes: [
            GoRoute(path: 'nueva', builder: (ctx, state) => const FormularioNoticiaScreen()),
            GoRoute(
              path: 'editar/:id',
              builder: (ctx, state) =>
                  FormularioNoticiaScreen(noticiaId: state.pathParameters['id']),
            ),
          ],
        ),
        GoRoute(
          path: '/testimonios',
          builder: (ctx, state) => const TestimoniosScreen(),
          routes: [
            GoRoute(path: 'nuevo', builder: (ctx, state) => const FormularioTestimonioScreen()),
            GoRoute(
              path: 'editar/:id',
              builder: (ctx, state) =>
                  FormularioTestimonioScreen(testimonioId: state.pathParameters['id']),
            ),
          ],
        ),
        GoRoute(
          path: '/solicitudes',
          builder: (ctx, state) => const SolicitudesScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (ctx, state) =>
                  DetalleSolicitudScreen(solicitudId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(path: '/paises', builder: (ctx, state) => const PaisesScreen()),
        GoRoute(path: '/perfil', builder: (ctx, state) => const PerfilScreen()),

        // ── Visitante ─────────────────────────────────────────────────────────
        GoRoute(path: '/visitante', builder: (ctx, state) => const VisitanteDashboardScreen()),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Página no encontrada'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Ir al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
