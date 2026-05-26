import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
// AppHelpers vive en app_theme.dart (mismo archivo que AppTheme)

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  DashboardStats? _stats;
  List<Pais> _paises = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      final futures = <Future>[ApiService.instance.getDashboardStats()];
      if (auth.isSuperadmin) futures.add(ApiService.instance.getPaises());

      final results = await Future.wait(futures);

      // Comprobar mounted tras toda operación async antes de llamar a setState.
      if (!mounted) return;

      setState(() {
        _stats = DashboardStats.fromJson(results[0] as Map<String, dynamic>);
        if (auth.isSuperadmin && results.length > 1) {
          _paises = results[1] as List<Pais>;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ─── AppBar con gradiente ─────────────────────────────────
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, ${usuario?.nombre.split(' ').first ?? 'Admin'} 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _RolBadge(rol: usuario?.rol ?? ''),
                              if (usuario?.paisAsignado != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  usuario!.paisAsignado!.nombre,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Notificaciones
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 26),
                          onPressed: _showNotifications,
                        ),
                        if ((_stats?.solicitudesPendientes ?? 0) > 0)
                          Positioned(
                            right: 8, top: 8,
                            child: Container(
                              width: 16, height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${_stats!.solicitudesPendientes}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Avatar
                    GestureDetector(
                      onTap: () => context.push('/perfil'),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white38, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(usuario?.nombre ?? 'U'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Contenido scrollable ─────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),

                    if (_loading)
                      _buildSkeletonStats()
                    else if (_error != null)
                      _buildErrorState()
                    else
                      _buildStats(auth),

                    const SizedBox(height: 24),

                    // Acceso rápido
                    Text(
                      'Acceso Rápido',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickAccess(auth),

                    // Portales (solo superadmin)
                    if (auth.isSuperadmin) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Portales',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPortalesCards(),
                    ],

                    const SizedBox(height: 80), // padding para nav bar
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ─── Bottom Navigation Bar ────────────────────────────────────
      bottomNavigationBar: _buildBottomNav(auth),

      // Cada pantalla de destino gestiona su propio FAB si lo necesita
    );
  }

  Widget _buildStats(AuthProvider auth) {
    final stats = _stats!;
    return Column(
      children: [
        // Solicitudes pendientes - destacada
        _StatCard(
          icon: Icons.inbox_outlined,
          label: 'Solicitudes Pendientes',
          value: '${stats.solicitudesPendientes}',
          color: AppTheme.pendienteColor,
          onTap: () => context.push('/solicitudes'),
          isHighlighted: stats.solicitudesPendientes > 0,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.newspaper_outlined,
                label: 'Noticias activas',
                value: '${stats.noticiasActivas}',
                subValue: 'de ${stats.noticiasTotal}',
                color: AppTheme.secondary,
                onTap: () => context.push('/noticias'),
                isCompact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.star_outline,
                label: 'Testimonios',
                value: '${stats.testimoniosPublicados}',
                subValue: 'publicados',
                color: AppTheme.tertiary,
                onTap: () => context.push('/testimonios'),
                isCompact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonStats() {
    return Column(
      children: [
        _SkeletonCard(height: 80),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SkeletonCard(height: 100)),
            const SizedBox(width: 12),
            Expanded(child: _SkeletonCard(height: 100)),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppTheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sin conexión',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.error)),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _loadStats,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(AuthProvider auth) {
    final items = <_QuickItem>[
      _QuickItem(Icons.inbox_outlined, 'Solicitudes', '/solicitudes',
          AppTheme.pendienteColor, true),
      _QuickItem(Icons.newspaper_outlined, 'Noticias', '/noticias',
          AppTheme.secondary, true),
      _QuickItem(Icons.star_outline, 'Testimonios', '/testimonios',
          AppTheme.tertiary, true),
      if (auth.isSuperadmin)
        _QuickItem(Icons.public_outlined, 'Portales', '/paises',
            AppTheme.primary, true),
      _QuickItem(Icons.person_outline, 'Perfil', '/perfil',
          AppTheme.outline, true),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1,
      children: items.map((item) => _QuickAccessCard(item: item)).toList(),
    );
  }

  Widget _buildPortalesCards() {
    if (_paises.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Column(
      children: _paises.map((pais) {
        final flag = AppHelpers.getPaisFlag(pais.codigo);
        final color = AppTheme.getPaisColor(pais.codigo);
        final activo = pais.activo;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/paises'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // AppHelpers.getPaisFlag evita duplicar la lógica de emojis
                    Text(flag, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pais.nombre,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (activo ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        activo ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          color: activo ? Colors.green : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: AppTheme.outline),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  BottomNavigationBar _buildBottomNav(AuthProvider auth) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) {
        setState(() => _currentIndex = i);
        switch (i) {
          case 0: break; // Ya estamos en dashboard
          case 1: context.push('/solicitudes'); break;
          case 2: context.push('/noticias'); break;
          case 3: context.push('/perfil'); break;
        }
      },
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryContainer,
      unselectedItemColor: AppTheme.outline,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w700, fontSize: 11,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inbox_outlined),
          activeIcon: Icon(Icons.inbox),
          label: 'Solicitudes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome_mosaic_outlined),
          activeIcon: Icon(Icons.auto_awesome_mosaic),
          label: 'Contenido',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationsPanel(
        pendingCount: _stats?.solicitudesPendientes ?? 0,
        onTapSolicitud: (id) {
          Navigator.pop(context);
          context.push('/solicitudes/$id').then((_) => _loadStats());
        },
        onVerTodas: () {
          Navigator.pop(context);
          context.push('/solicitudes').then((_) => _loadStats());
        },
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    final word = parts[0];
    return word.substring(0, word.length.clamp(0, 2)).toUpperCase();
  }
}

// ─── Componentes internos ─────────────────────────────────────────────────────
class _RolBadge extends StatelessWidget {
  final String rol;
  const _RolBadge({required this.rol});

  @override
  Widget build(BuildContext context) {
    String label;
    switch (rol) {
      case 'superadmin': label = 'Super Admin'; break;
      case 'admin_pais': label = 'Admin País'; break;
      case 'editor': label = 'Editor'; break;
      case 'visitante': label = 'Visitante'; break;
      default: label = rol;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(
        color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600,
      )),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final Color color;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final bool isCompact;

  const _StatCard({
    required this.icon, required this.label,
    required this.value, this.subValue,
    required this.color, this.onTap,
    this.isHighlighted = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isHighlighted
                ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isCompact ? _buildCompact() : _buildHorizontal(),
        ),
      ),
    );
  }

  Widget _buildHorizontal() {
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(
                fontSize: 12, color: AppTheme.onSurfaceVariant,
              )),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: const Alignment(-1, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800,
                      color: color,
                    )),
                    if (subValue != null) ...[
                      const SizedBox(width: 4),
                      Text(subValue!, style: TextStyle(
                        fontSize: 12, color: AppTheme.outline,
                      )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: AppTheme.outlineVariant),
      ],
    );
  }

  Widget _buildCompact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Icon(Icons.chevron_right, color: AppTheme.outlineVariant, size: 18),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800, color: color,
            )),
            if (subValue != null) ...[
              const SizedBox(width: 4),
              Text(subValue!, style: TextStyle(
                fontSize: 11, color: AppTheme.outline,
              )),
            ],
          ],
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;
  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  final bool enabled;

  _QuickItem(this.icon, this.label, this.route, this.color, this.enabled);
}

class _QuickAccessCard extends StatelessWidget {
  final _QuickItem item;
  const _QuickAccessCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(item.route),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Panel de notificaciones ──────────────────────────────────────────────────
class _NotificationsPanel extends StatefulWidget {
  final int pendingCount;
  final void Function(String id) onTapSolicitud;
  final VoidCallback onVerTodas;

  const _NotificationsPanel({
    required this.pendingCount,
    required this.onTapSolicitud,
    required this.onVerTodas,
  });

  @override
  State<_NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<_NotificationsPanel> {
  List<Solicitud> _solicitudes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.instance.getSolicitudes(
        estado: 'pendiente',
        page: 1,
      );
      final lista = (data['solicitudes'] as List)
          .map((j) => Solicitud.fromJson(j))
          .toList();
      if (mounted) setState(() { _solicitudes = lista; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Notificaciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                if (widget.pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.pendienteColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${widget.pendingCount} pendiente${widget.pendingCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: AppTheme.pendienteColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),

          // ── Contenido ────────────────────────────────────────────
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.wifi_off, size: 40, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('Error al cargar',
                      style: TextStyle(color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                ],
              ),
            )
          else if (_solicitudes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline,
                        size: 40, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  const Text('¡Todo al día!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'No hay solicitudes pendientes de atención.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _solicitudes.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 76),
                itemBuilder: (_, i) => _NotifItem(
                  solicitud: _solicitudes[i],
                  onTap: () => widget.onTapSolicitud(_solicitudes[i].id),
                ),
              ),
            ),

          // ── Footer ───────────────────────────────────────────────
          if (!_loading && _error == null) ...[
            const Divider(height: 1),
            InkWell(
              onTap: widget.onVerTodas,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 16, color: AppTheme.primaryContainer),
                    const SizedBox(width: 6),
                    Text(
                      'Ver todas las solicitudes',
                      style: TextStyle(
                        color: AppTheme.primaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ],
      ),
    );
  }
}

// ─── Ítem de notificación ─────────────────────────────────────────────────────
class _NotifItem extends StatelessWidget {
  final Solicitud solicitud;
  final VoidCallback onTap;

  const _NotifItem({required this.solicitud, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fecha = solicitud.fechaCreacion;
    final fechaStr = fecha != null ? _formatFecha(fecha) : '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Avatar con inicial
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
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    solicitud.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Finalidad
                  Text(
                    solicitud.finalidad,
                    style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // Tags: estado + país + fecha
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.pendienteColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Pendiente',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.pendienteColor,
                          ),
                        ),
                      ),
                      if (solicitud.pais != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${AppHelpers.getPaisFlag(solicitud.pais!.codigo)} ${solicitud.pais!.nombre}',
                          style: TextStyle(fontSize: 11, color: AppTheme.outline),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        fechaStr,
                        style: TextStyle(fontSize: 10, color: AppTheme.outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: AppTheme.outlineVariant),
          ],
        ),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final diff = now.difference(fecha);
    if (diff.inMinutes < 1)  return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24)   return 'hace ${diff.inHours}h';
    if (diff.inDays < 7)     return 'hace ${diff.inDays}d';
    return DateFormat('dd/MM/yyyy').format(fecha);
  }
}
