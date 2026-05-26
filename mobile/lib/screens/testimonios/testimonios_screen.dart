import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class TestimoniosScreen extends StatefulWidget {
  const TestimoniosScreen({super.key});

  @override
  State<TestimoniosScreen> createState() => _TestimoniosScreenState();
}

class _TestimoniosScreenState extends State<TestimoniosScreen> {
  List<Testimonio> _testimonios = [];
  bool _loading = true;
  String? _filtroEstado;
  int _page = 1;
  bool _hasMore = true;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargar();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_loading) { _page++; _cargar(reset: false); }
    }
  }

  Future<void> _cargar({bool reset = true}) async {
    if (reset) setState(() { _loading = true; _page = 1; _testimonios = []; });
    try {
      final data = await ApiService.instance.getTestimonios(
        estado: _filtroEstado, page: _page,
      );
      final lista = (data['testimonios'] as List).map((j) => Testimonio.fromJson(j)).toList();
      setState(() {
        _testimonios = reset ? lista : [..._testimonios, ...lista];
        _hasMore = _page < (data['totalPages'] ?? 1);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _cambiarEstado(Testimonio t, String nuevoEstado) async {
    try {
      await ApiService.instance.cambiarEstadoTestimonio(t.id, nuevoEstado);
      _cargar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _eliminar(Testimonio t) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Eliminar testimonio',
      message: '¿Eliminar el testimonio de "${t.nombre}"?',
    );
    if (!confirm) return;
    try {
      await ApiService.instance.eliminarTestimonio(t.id);
      _cargar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: GradientAppBar(
        title: 'Testimonios de Éxito',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (v) {
              setState(() => _filtroEstado = v.isEmpty ? null : v);
              _cargar();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: '', child: Text('Todos')),
              const PopupMenuItem(value: 'publicado', child: Text('Publicados')),
              const PopupMenuItem(value: 'borrador', child: Text('Borradores')),
              const PopupMenuItem(value: 'despublicado', child: Text('Despublicados')),
            ],
          ),
        ],
      ),
      body: _loading && _testimonios.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _testimonios.isEmpty
              ? EmptyState(
                  icon: Icons.star_outline,
                  title: 'Sin testimonios',
                  subtitle: 'Agrega el primer testimonio de éxito',
                  actionLabel: 'Agregar testimonio',
                  onAction: () => context.push('/testimonios/nuevo').then((_) => _cargar()),
                )
              : RefreshIndicator(
                  onRefresh: () => _cargar(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _testimonios.length + (_hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _testimonios.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final t = _testimonios[i];
                      return _TestimonioCard(
                        testimonio: t,
                        onEdit: () => context
                            .push('/testimonios/editar/${t.id}')
                            .then((_) => _cargar()),
                        onEstado: (estado) => _cambiarEstado(t, estado),
                        onDelete: auth.puedeEliminar ? () => _eliminar(t) : null,
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/testimonios/nuevo').then((_) => _cargar()),
        backgroundColor: AppTheme.primaryContainer,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo testimonio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _TestimonioCard extends StatelessWidget {
  final Testimonio testimonio;
  final VoidCallback onEdit;
  final void Function(String) onEstado;
  final VoidCallback? onDelete;

  const _TestimonioCard({
    required this.testimonio, required this.onEdit,
    required this.onEstado, this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getEstadoContenidoColor(testimonio.estado);
    final fecha = testimonio.fechaCreacion;
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
            children: [
              Row(
                children: [
                  // Foto
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: testimonio.fotoUrl,
                      width: 56, height: 56,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 56, height: 56,
                        color: AppTheme.surfaceContainerHigh,
                        child: const Icon(Icons.person, color: AppTheme.outline),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 56, height: 56,
                        color: AppTheme.surfaceContainerHigh,
                        child: const Icon(Icons.person, color: AppTheme.outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testimonio.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (testimonio.pais != null) ...[
                              PaisChip(
                                nombre: testimonio.pais!.nombre,
                                codigo: testimonio.pais!.codigo,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(fechaStr, style: TextStyle(
                              fontSize: 11, color: AppTheme.outline,
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Estado actual
                  StatusChip(
                    label: _labelEstado(testimonio.estado),
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                testimonio.testimonio,
                style: TextStyle(
                  fontSize: 13, color: AppTheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Controles de estado — chips en scroll para evitar overflow en pantallas pequeñas
              Row(
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _EstadoChip('borrador', testimonio.estado == 'borrador',
                            AppTheme.borradorColor, () => onEstado('borrador')),
                          const SizedBox(width: 6),
                          _EstadoChip('publicado', testimonio.estado == 'publicado',
                            AppTheme.publicadoColor, () => onEstado('publicado')),
                          const SizedBox(width: 6),
                          _EstadoChip('despublicado', testimonio.estado == 'despublicado',
                            AppTheme.despublicadoColor, () => onEstado('despublicado')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppTheme.primaryContainer,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: onEdit,
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: AppTheme.error,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelEstado(String e) {
    switch (e) {
      case 'publicado': return 'Publicado';
      case 'borrador': return 'Borrador';
      case 'despublicado': return 'Inactivo';
      default: return e;
    }
  }
}

class _EstadoChip extends StatelessWidget {
  final String estado;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _EstadoChip(this.estado, this.selected, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          estado,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
