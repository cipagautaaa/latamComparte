import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  runApp(const LatamComparteApp());
}

class LatamComparteApp extends StatefulWidget {
  const LatamComparteApp({super.key});

  @override
  State<LatamComparteApp> createState() => _LatamComparteAppState();
}

class _LatamComparteAppState extends State<LatamComparteApp> {
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    // Inicializar auth al arrancar
    _authProvider.init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _authProvider,
      child: Builder(
        builder: (context) {
          final router = AppRouter.createRouter(_authProvider);
          return MaterialApp.router(
            title: 'Latinoamérica Comparte',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
