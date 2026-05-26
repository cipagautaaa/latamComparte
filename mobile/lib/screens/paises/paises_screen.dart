import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common_widgets.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';

class PaisesScreen extends StatefulWidget {
  const PaisesScreen({super.key});

  @override
  State<PaisesScreen> createState() => _PaisesScreenState();
}

class _PaisesScreenState extends State<PaisesScreen> {
  List<Pais> _paises = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final paises = await ApiService.instance.getPaises();
      if (mounted) setState(() { _paises = paises; _cargando = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  Future<void> _toggleEstado(Pais pais) async {
    final confirm = await showConfirmDialog(
      context,
      title: pais.activo ? 'Desactivar portal' : 'Activar portal',
      message: '¿Deseas ${pais.activo ? "desactivar" : "activar"} el portal de ${pais.nombre}?',
      confirmLabel: pais.activo ? 'Desactivar' : 'Activar',
      esDestructivo: pais.activo,
    );
    if (!confirm) return;

    try {
      await ApiService.instance.actualizarEstadoPais(pais.id, !pais.activo);
      _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Portal ${pais.nombre} ${!pais.activo ? "activado" : "desactivado"}'),
            backgroundColor: !pais.activo ? AppColors.success : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();

    // Bloquear acceso si no es superadmin
    if (!authProv.isSuperadmin) {
      return Scaffold(
        appBar: GradientAppBar(title: 'Portales'),
        body: const EmptyState(
          icon: Icons.lock_outlined,
          title: 'Acceso restringido',
          subtitle: 'Solo el superadministrador puede gestionar los portales.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Portales',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error: $_error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : _paises.isEmpty
                  ? const EmptyState(
                      icon: Icons.public_off,
                      title: 'Sin portales',
                      subtitle: 'No hay portales registrados.',
                    )
                  : Column(
                      children: [
                        // Header estadísticas
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryLight, AppColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha:0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.public, color: Colors.white, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Portales Multipaís',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        )),
                                    Text(
                                      '${_paises.where((p) => p.activo).length} activos · ${_paises.length} total',
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Lista de países
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _paises.length,
                            itemBuilder: (ctx, i) => _PaisCard(
                              pais: _paises[i],
                              onToggle: () => _toggleEstado(_paises[i]),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _PaisCard extends StatelessWidget {
  final Pais pais;
  final VoidCallback onToggle;

  const _PaisCard({required this.pais, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final color = AppHelpers.getPaisColor(pais.codigo);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: pais.activo ? color.withValues(alpha:0.3) : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Flag & color badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  AppHelpers.getPaisFlag(pais.codigo),
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pais.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          pais.codigo,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        label: pais.activo ? 'Activo' : 'Inactivo',
                        color: pais.activo ? AppColors.success : Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Toggle estado
            Column(
              children: [
                Switch(
                  value: pais.activo,
                  onChanged: (_) => onToggle(),
                  activeColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha:0.3),
                ),
                Text(
                  pais.activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 11,
                    color: pais.activo ? AppColors.success : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
