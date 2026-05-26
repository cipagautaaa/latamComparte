import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class VisitanteDashboardScreen extends StatefulWidget {
  const VisitanteDashboardScreen({super.key});

  @override
  State<VisitanteDashboardScreen> createState() => _VisitanteDashboardScreenState();
}

class _VisitanteDashboardScreenState extends State<VisitanteDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 0;

  // Key para poder llamar cargar() en el tab desde el FAB del padre
  final _miSolicitudKey = GlobalKey<_MiSolicitudTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _tabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _abrirFormulario() async {
    final auth = context.read<AuthProvider>();
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FormularioSolicitudSheet(
        nombreInicial: auth.usuario?.nombre ?? '',
        correoInicial: auth.usuario?.correo ?? '',
      ),
    );
    // Refrescar siempre al cerrar el sheet: la solicitud puede haberse
    // creado aunque el sheet se haya cerrado antes de recibir la respuesta.
    if (mounted) {
      _miSolicitudKey.currentState?.cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final usuario = auth.usuario;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + kTextTabBarHeight),
        child: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${usuario?.nombre.split(' ').first ?? 'Visitante'} 👋',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Visitante',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Cerrar sesión',
                onPressed: () => context.read<AuthProvider>().logout(),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(icon: Icon(Icons.newspaper_outlined, size: 20), text: 'Noticias'),
                Tab(icon: Icon(Icons.star_outline, size: 20), text: 'Testimonios'),
                Tab(icon: Icon(Icons.inbox_outlined, size: 20), text: 'Mi Solicitud'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _NoticiasTab(),
          const _TestimoniosTab(),
          _MiSolicitudTab(key: _miSolicitudKey),
        ],
      ),
      // FAB solo en el tab "Mi Solicitud"
      floatingActionButton: _tabIndex == 2
          ? FloatingActionButton.extended(
              onPressed: _abrirFormulario,
              backgroundColor: AppTheme.primaryContainer,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nueva solicitud',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }
}

// ─── Bottom sheet: formulario de nueva solicitud ──────────────────────────────
class _FormularioSolicitudSheet extends StatefulWidget {
  final String nombreInicial;
  final String correoInicial;

  const _FormularioSolicitudSheet({
    required this.nombreInicial,
    required this.correoInicial,
  });

  @override
  State<_FormularioSolicitudSheet> createState() => _FormularioSolicitudSheetState();
}

class _FormularioSolicitudSheetState extends State<_FormularioSolicitudSheet> {
  final _formKey       = GlobalKey<FormState>();
  final _telefonoCtrl  = TextEditingController();
  final _finalidadCtrl = TextEditingController();

  List<Pais> _paises = [];
  String? _paisId;
  bool _enviando = false;
  bool _cargandoPaises = true;

  @override
  void initState() {
    super.initState();
    _cargarPaises();
  }

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    _finalidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPaises() async {
    try {
      final paises = await ApiService.instance.getPaisesPublico();
      if (mounted) setState(() { _paises = paises; _cargandoPaises = false; });
    } catch (_) {
      if (mounted) setState(() => _cargandoPaises = false);
    }
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paisId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu país'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (widget.nombreInicial.isEmpty || widget.correoInicial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de sesión. Cierra sesión e ingresa nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      await ApiService.instance.crearSolicitudPublica({
        'nombre':    widget.nombreInicial,
        'correo':    widget.correoInicial,
        'telefono':  _telefonoCtrl.text.trim(),
        'finalidad': _finalidadCtrl.text.trim(),
        'pais':      _paisId,
      });

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_enviando,
      child: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle visual
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text(
                'Nueva solicitud',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Cuéntanos en qué podemos ayudarte',
                style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // Correo de solo lectura — se usa para vincular la solicitud al visitante
              _CampoReadonly(
                label: 'Correo',
                value: widget.correoInicial,
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 12),

              AppTextField(
                label: 'Teléfono / WhatsApp *',
                hint: '+57 300 123 4567',
                controller: _telefonoCtrl,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo requerido';
                  if (v.length < 7) return 'Teléfono inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Selector de país desde la BD
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'País *',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _cargandoPaises
                      ? const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ))
                      : DropdownButtonFormField<String>(
                          initialValue: _paisId,
                          hint: const Text('Selecciona tu país'),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.flag_outlined, color: AppTheme.outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceContainerLow,
                          ),
                          items: _paises.map((p) {
                            final flag = AppHelpers.getPaisFlag(p.codigo);
                            return DropdownMenuItem(
                              value: p.id,
                              child: Text('$flag  ${p.nombre}'),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _paisId = v),
                          validator: (v) => v == null ? 'Selecciona tu país' : null,
                        ),
                ],
              ),
              const SizedBox(height: 12),

              AppTextField(
                label: '¿En qué podemos ayudarte? *',
                hint: 'Describe brevemente lo que necesitas...',
                controller: _finalidadCtrl,
                maxLines: 4,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo requerido';
                  if (v.length < 10) return 'Por favor sé más específico';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              GradientButton(
                label: 'Enviar solicitud',
                icon: Icons.send_outlined,
                isLoading: _enviando,
                onPressed: _enviando ? null : _enviar,
              ),
            ],
          ),
        ),
      ),
    ),   // Container
  );     // PopScope
  }

}

// Campo de solo lectura con estilo consistente con AppTextField
class _CampoReadonly extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CampoReadonly({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.outline),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
              ),
              Icon(Icons.lock_outline, size: 14, color: AppTheme.outline),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab Noticias ─────────────────────────────────────────────────────────────
class _NoticiasTab extends StatefulWidget {
  const _NoticiasTab();

  @override
  State<_NoticiasTab> createState() => _NoticiasTabState();
}

class _NoticiasTabState extends State<_NoticiasTab> with AutomaticKeepAliveClientMixin {
  List<Noticia> _noticias = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      // getNoticiasPublicas() ya devuelve List<Noticia> — sin cast manual
      final data = await ApiService.instance.getNoticiasPublicas();
      if (!mounted) return;
      setState(() { _noticias = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: AppTheme.outline),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(onPressed: _cargar, child: const Text('Reintentar')),
        ],
      ));
    }
    if (_noticias.isEmpty) {
      return const EmptyState(
        icon: Icons.newspaper_outlined,
        title: 'Sin noticias',
        subtitle: 'No hay noticias publicadas por el momento',
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _noticias.length,
        itemBuilder: (ctx, i) => _NoticiaCard(noticia: _noticias[i]),
      ),
    );
  }
}

class _NoticiaCard extends StatelessWidget {
  final Noticia noticia;
  const _NoticiaCard({required this.noticia});

  @override
  Widget build(BuildContext context) {
    final fecha    = noticia.fechaCreacion;
    final fechaStr = fecha != null ? DateFormat('dd MMM yyyy', 'es').format(fecha) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      noticia.titulo,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  if (noticia.pais != null)
                    PaisChip(nombre: noticia.pais!.nombre, codigo: noticia.pais!.codigo),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                noticia.resumen,
                style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 13, color: AppTheme.outline),
                  const SizedBox(width: 4),
                  Text(noticia.autor, style: TextStyle(fontSize: 12, color: AppTheme.outline)),
                  const SizedBox(width: 12),
                  Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.outline),
                  const SizedBox(width: 4),
                  Text(fechaStr, style: TextStyle(fontSize: 12, color: AppTheme.outline)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab Testimonios ──────────────────────────────────────────────────────────
class _TestimoniosTab extends StatefulWidget {
  const _TestimoniosTab();

  @override
  State<_TestimoniosTab> createState() => _TestimoniosTabState();
}

class _TestimoniosTabState extends State<_TestimoniosTab> with AutomaticKeepAliveClientMixin {
  List<Testimonio> _testimonios = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      // getTestimoniosPublicos() ya devuelve List<Testimonio> — sin cast manual
      final data = await ApiService.instance.getTestimoniosPublicos();
      if (!mounted) return;
      setState(() { _testimonios = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: AppTheme.outline),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(onPressed: _cargar, child: const Text('Reintentar')),
        ],
      ));
    }
    if (_testimonios.isEmpty) {
      return const EmptyState(
        icon: Icons.star_outline,
        title: 'Sin testimonios',
        subtitle: 'No hay testimonios publicados por el momento',
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _testimonios.length,
        itemBuilder: (ctx, i) => _TestimonioCard(testimonio: _testimonios[i]),
      ),
    );
  }
}

class _TestimonioCard extends StatelessWidget {
  final Testimonio testimonio;
  const _TestimonioCard({required this.testimonio});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: AppTheme.primaryContainer),
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
                            testimonio.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        if (testimonio.pais != null)
                          PaisChip(nombre: testimonio.pais!.nombre, codigo: testimonio.pais!.codigo),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"${testimonio.testimonio}"',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab Mi Solicitud ─────────────────────────────────────────────────────────
class _MiSolicitudTab extends StatefulWidget {
  const _MiSolicitudTab({super.key});

  @override
  State<_MiSolicitudTab> createState() => _MiSolicitudTabState();
}

class _MiSolicitudTabState extends State<_MiSolicitudTab> with AutomaticKeepAliveClientMixin {
  List<Solicitud> _solicitudes = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // Expuesto para que el padre lo llame al crear una solicitud nueva
  Future<void> cargar() => _cargar();

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      // getMiSolicitud() ya devuelve List<Solicitud> — sin cast manual
      final data = await ApiService.instance.getMiSolicitud();
      if (!mounted) return;
      setState(() { _solicitudes = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: AppTheme.outline),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(onPressed: _cargar, child: const Text('Reintentar')),
        ],
      ));
    }
    if (_solicitudes.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'Sin solicitudes',
        subtitle: 'Aún no has enviado ninguna solicitud.\nToca el botón + para crear una.',
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _solicitudes.length,
        itemBuilder: (ctx, i) => _SolicitudCard(solicitud: _solicitudes[i]),
      ),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final Solicitud solicitud;
  const _SolicitudCard({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final fecha    = solicitud.fechaCreacion;
    final fechaStr = fecha != null ? DateFormat('dd MMM yyyy', 'es').format(fecha) : '';
    final color    = _colorEstado(solicitud.estado);
    final label    = _labelEstado(solicitud.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      solicitud.finalidad,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  StatusChip(label: label, color: color),
                ],
              ),
              const SizedBox(height: 8),
              if (solicitud.pais != null)
                PaisChip(nombre: solicitud.pais!.nombre, codigo: solicitud.pais!.codigo),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.outline),
                  const SizedBox(width: 4),
                  Text(fechaStr, style: TextStyle(fontSize: 12, color: AppTheme.outline)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(_iconoEstado(solicitud.estado), color: color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _descripcionEstado(solicitud.estado),
                        style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente':  return AppTheme.pendienteColor;
      case 'gestionada': return Colors.blue;
      case 'respondida': return Colors.green;
      default:           return AppTheme.outline;
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'pendiente':  return 'Pendiente';
      case 'gestionada': return 'En gestión';
      case 'respondida': return 'Respondida';
      default:           return estado;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'pendiente':  return Icons.hourglass_empty;
      case 'gestionada': return Icons.pending_actions;
      case 'respondida': return Icons.check_circle_outline;
      default:           return Icons.info_outline;
    }
  }

  String _descripcionEstado(String estado) {
    switch (estado) {
      case 'pendiente':  return 'Tu solicitud fue recibida y está en espera de revisión.';
      case 'gestionada': return 'Tu solicitud está siendo gestionada por nuestro equipo.';
      case 'respondida': return 'Tu solicitud fue atendida. Revisa tu correo para más detalles.';
      default:           return '';
    }
  }
}
