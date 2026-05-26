import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class DetalleSolicitudScreen extends StatefulWidget {
  final String solicitudId;
  const DetalleSolicitudScreen({super.key, required this.solicitudId});

  @override
  State<DetalleSolicitudScreen> createState() => _DetalleSolicitudScreenState();
}

class _DetalleSolicitudScreenState extends State<DetalleSolicitudScreen> {
  Solicitud? _solicitud;
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.getSolicitud(widget.solicitudId);
      setState(() {
        _solicitud = Solicitud.fromJson(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    setState(() => _updating = true);
    try {
      final data = await ApiService.instance
          .actualizarEstadoSolicitud(widget.solicitudId, nuevoEstado);
      setState(() {
        _solicitud = Solicitud.fromJson(data);
        _updating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a "$nuevoEstado"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _updating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _eliminar() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Eliminar solicitud',
      message: '¿Estás seguro de eliminar esta solicitud? Esta acción no se puede deshacer.',
    );
    if (!confirm) return;

    setState(() => _updating = true);
    try {
      await ApiService.instance.eliminarSolicitud(widget.solicitudId);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud eliminada'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _updating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: GradientAppBar(
        title: 'Detalle de Solicitud',
        actions: [
          if (auth.puedeEliminar)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _updating ? null : _eliminar,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _solicitud == null
              ? const EmptyState(
                  icon: Icons.error_outline,
                  title: 'Solicitud no encontrada',
                )
              : LoadingOverlay(
                  isLoading: _updating,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Header ───────────────────────────
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 56, height: 56,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradientVertical,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _solicitud!.nombre[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _solicitud!.nombre,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          StatusChip(
                                            label: _labelEstado(_solicitud!.estado),
                                            color: AppTheme.getEstadoSolicitudColor(_solicitud!.estado),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 12),
                                _InfoRow(
                                  icon: Icons.mail_outline,
                                  label: 'Correo',
                                  value: _solicitud!.correo,
                                ),
                                const SizedBox(height: 12),
                                _InfoRow(
                                  icon: Icons.phone_outlined,
                                  label: 'Teléfono',
                                  value: _solicitud!.telefono,
                                ),
                                const SizedBox(height: 12),
                                _InfoRow(
                                  icon: Icons.info_outline,
                                  label: 'Finalidad',
                                  value: _solicitud!.finalidad,
                                ),
                                if (_solicitud!.pais != null) ...[
                                  const SizedBox(height: 12),
                                  _InfoRow(
                                    icon: Icons.public_outlined,
                                    label: 'País',
                                    value: _solicitud!.pais!.nombre,
                                  ),
                                ],
                                if (_solicitud!.fechaCreacion != null) ...[
                                  const SizedBox(height: 12),
                                  _InfoRow(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'Fecha',
                                    value: DateFormat('dd MMMM yyyy, HH:mm', 'es')
                                        .format(_solicitud!.fechaCreacion!),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ─── Cambiar estado ────────────────────
                        Text(
                          'Cambiar estado',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _EstadoBtn(
                              label: 'Pendiente',
                              estado: 'pendiente',
                              color: AppTheme.pendienteColor,
                              selected: _solicitud!.estado == 'pendiente',
                              onTap: () => _cambiarEstado('pendiente'),
                            ),
                            const SizedBox(width: 8),
                            _EstadoBtn(
                              label: 'Gestionada',
                              estado: 'gestionada',
                              color: AppTheme.gestionadaColor,
                              selected: _solicitud!.estado == 'gestionada',
                              onTap: () => _cambiarEstado('gestionada'),
                            ),
                            const SizedBox(width: 8),
                            _EstadoBtn(
                              label: 'Respondida',
                              estado: 'respondida',
                              color: AppTheme.respondidaColor,
                              selected: _solicitud!.estado == 'respondida',
                              onTap: () => _cambiarEstado('respondida'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ─── Acción eliminar ───────────────────
                        if (auth.puedeEliminar)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Eliminar solicitud'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.error,
                                side: const BorderSide(color: AppTheme.error),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _updating ? null : _eliminar,
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _labelEstado(String e) {
    switch (e) {
      case 'pendiente': return 'Pendiente';
      case 'gestionada': return 'Gestionada';
      case 'respondida': return 'Respondida';
      default: return e;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.outline),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(
                fontSize: 11, color: AppTheme.outline, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _EstadoBtn extends StatelessWidget {
  final String label;
  final String estado;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _EstadoBtn({
    required this.label, required this.estado,
    required this.color, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3), width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}
