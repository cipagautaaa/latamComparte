import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen>
    with WidgetsBindingObserver {
  List<Solicitud> _solicitudes = [];
  List<Pais> _paises = [];
  bool _loading = true;
  String? _error;
  String? _filtroEstado;
  String? _filtroPais;
  int _page = 1;
  bool _hasMore = true;

  final _scrollController = ScrollController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarSolicitudes();
    _cargarPaises();
    _scrollController.addListener(_onScroll);
    // Refresca cada 30 segundos para que el admin vea nuevas solicitudes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_loading) _cargarSolicitudes();
    });
  }

  // Refresca al volver al primer plano (ej: el admin tenía la app en background)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && !_loading) {
      _cargarSolicitudes();
    }
  }

  Future<void> _cargarPaises() async {
    try {
      final data = await ApiService.instance.getPaises();
      if (mounted) setState(() => _paises = data);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_loading) _cargarMas();
    }
  }

  Future<void> _cargarSolicitudes({bool reset = true}) async {
    if (reset) {
      setState(() { _loading = true; _page = 1; _solicitudes = []; });
    }
    try {
      final data = await ApiService.instance.getSolicitudes(
        estado: _filtroEstado,
        pais: _filtroPais,
        page: _page,
      );
      final lista = (data['solicitudes'] as List)
          .map((j) => Solicitud.fromJson(j))
          .toList();
      setState(() {
        _solicitudes = reset ? lista : [..._solicitudes, ...lista];
        _hasMore = _page < (data['totalPages'] ?? 1);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _cargarMas() async {
    _page++;
    await _cargarSolicitudes(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: GradientAppBar(
        title: 'Solicitudes de Contacto',
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Actualizar lista',
              onPressed: () => _cargarSolicitudes(),
            ),
          IconButton(
            icon: Badge(
              isLabelVisible: _filtroEstado != null || _filtroPais != null,
              child: const Icon(Icons.filter_list, color: Colors.white),
            ),
            onPressed: () => _showFiltros(context, auth),
          ),
        ],
      ),
      body: _loading && _solicitudes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _solicitudes.isEmpty
              ? EmptyState(
                  icon: Icons.wifi_off,
                  title: 'Error de conexión',
                  subtitle: _error,
                  actionLabel: 'Reintentar',
                  onAction: () => _cargarSolicitudes(),
                )
              : _solicitudes.isEmpty
                  ? EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'Sin solicitudes',
                      subtitle: 'No hay solicitudes con los filtros seleccionados',
                    )
                  : RefreshIndicator(
                      onRefresh: () => _cargarSolicitudes(),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _solicitudes.length + (_hasMore ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == _solicitudes.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return _SolicitudCard(
                            solicitud: _solicitudes[i],
                            onTap: () => context
                                .push('/solicitudes/${_solicitudes[i].id}')
                                .then((_) => _cargarSolicitudes()),
                          );
                        },
                      ),
                    ),
    );
  }

  void _showFiltros(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filtros', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                  )),
                  TextButton(
                    onPressed: () {
                      setModalState(() {});
                      setState(() { _filtroEstado = null; _filtroPais = null; });
                      Navigator.pop(ctx);
                      _cargarSolicitudes();
                    },
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Estado', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant,
              )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['pendiente', 'gestionada', 'respondida']
                    .map((e) => FilterChip(
                          label: Text(e),
                          selected: _filtroEstado == e,
                          selectedColor: AppTheme.getEstadoSolicitudColor(e).withValues(alpha: 0.2),
                          onSelected: (v) {
                            setModalState(() => _filtroEstado = v ? e : null);
                          },
                        ))
                    .toList(),
              ),
              if (auth.isSuperadmin && _paises.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('País', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant,
                )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _paises.map((p) => FilterChip(
                        label: Text(p.nombre),
                        selected: _filtroPais == p.id,
                        onSelected: (v) {
                          setModalState(() => _filtroPais = v ? p.id : null);
                        },
                      )).toList(),
                ),
              ],
              const SizedBox(height: 20),
              GradientButton(
                label: 'Aplicar filtros',
                onPressed: () {
                  Navigator.pop(ctx);
                  _cargarSolicitudes();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final Solicitud solicitud;
  final VoidCallback onTap;

  const _SolicitudCard({required this.solicitud, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getEstadoSolicitudColor(solicitud.estado);
    final fecha = solicitud.fechaCreacion;
    final fechaStr = fecha != null
        ? DateFormat('dd MMM yyyy', 'es').format(fecha)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradientVertical,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      solicitud.nombre.isNotEmpty
                          ? solicitud.nombre[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              solicitud.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StatusChip(
                            label: _labelEstado(solicitud.estado),
                            color: color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        solicitud.finalidad,
                        style: TextStyle(
                          fontSize: 12, color: AppTheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (solicitud.pais != null) ...[
                            PaisChip(
                              nombre: solicitud.pais!.nombre,
                              codigo: solicitud.pais!.codigo,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            fechaStr,
                            style: TextStyle(
                              fontSize: 11, color: AppTheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: AppTheme.outlineVariant, size: 20),
              ],
            ),
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
