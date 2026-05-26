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

class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});

  @override
  State<NoticiasScreen> createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends State<NoticiasScreen> {
  List<Noticia> _noticias = [];
  bool _loading = true;
  String? _error;
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
    if (reset) setState(() { _loading = true; _page = 1; _noticias = []; });
    try {
      final data = await ApiService.instance.getNoticias(
        estado: _filtroEstado, page: _page,
      );
      final lista = (data['noticias'] as List).map((j) => Noticia.fromJson(j)).toList();
      setState(() {
        _noticias = reset ? lista : [..._noticias, ...lista];
        _hasMore = _page < (data['totalPages'] ?? 1);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggleEstado(Noticia noticia) async {
    final nuevoEstado = noticia.estado == 'publicado' ? 'borrador' : 'publicado';
    try {
      await ApiService.instance.cambiarEstadoNoticia(noticia.id, nuevoEstado);
      _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _eliminar(Noticia noticia) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Eliminar noticia',
      message: '¿Eliminar "${noticia.titulo}"?',
    );
    if (!confirm) return;
    try {
      await ApiService.instance.eliminarNoticia(noticia.id);
      _cargar();
    } catch (e) {
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
        title: 'Noticias',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (v) {
              setState(() => _filtroEstado = v.isEmpty ? null : v);
              _cargar();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: '', child: Text('Todas')),
              const PopupMenuItem(value: 'publicado', child: Text('Publicadas')),
              const PopupMenuItem(value: 'borrador', child: Text('Borradores')),
            ],
          ),
        ],
      ),
      body: _loading && _noticias.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _noticias.isEmpty
              ? EmptyState(
                  icon: Icons.newspaper_outlined,
                  title: 'Sin noticias',
                  subtitle: 'Crea la primera noticia para comenzar',
                  actionLabel: 'Crear noticia',
                  onAction: () => context.push('/noticias/nueva').then((_) => _cargar()),
                )
              : RefreshIndicator(
                  onRefresh: () => _cargar(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _noticias.length + (_hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _noticias.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      return _NoticiaCard(
                        noticia: _noticias[i],
                        onEdit: () => context
                            .push('/noticias/editar/${_noticias[i].id}')
                            .then((_) => _cargar()),
                        onToggle: () => _toggleEstado(_noticias[i]),
                        onDelete: auth.puedeEliminar
                            ? () => _eliminar(_noticias[i])
                            : null,
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/noticias/nueva').then((_) => _cargar()),
        backgroundColor: AppTheme.primaryContainer,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva noticia',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _NoticiaCard extends StatelessWidget {
  final Noticia noticia;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const _NoticiaCard({
    required this.noticia, required this.onEdit,
    required this.onToggle, this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getEstadoContenidoColor(noticia.estado);
    final fecha = noticia.fechaCreacion;
    final fechaStr = fecha != null ? DateFormat('dd MMM', 'es').format(fecha) : '';

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
                  // Imagen o placeholder
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: noticia.imagenUrl != null
                        ? CachedNetworkImage(
                            imageUrl: noticia.imagenUrl!,
                            width: 56, height: 56,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _PlaceholderImg(),
                            errorWidget: (_, __, ___) => _PlaceholderImg(),
                          )
                        : _PlaceholderImg(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          noticia.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (noticia.pais != null) ...[
                              PaisChip(
                                nombre: noticia.pais!.nombre,
                                codigo: noticia.pais!.codigo,
                              ),
                              const SizedBox(width: 6),
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
                  // Toggle estado
                  GestureDetector(
                    onTap: onToggle,
                    child: StatusChip(
                      label: noticia.estado == 'publicado' ? 'Activa' : 'Borrador',
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                noticia.resumen,
                style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Por ${noticia.autor}',
                    style: TextStyle(fontSize: 11, color: AppTheme.outline),
                  ),
                  const Spacer(),
                  _ActionBtn(Icons.edit_outlined, 'Editar', onEdit),
                  const SizedBox(width: 8),
                  if (onDelete != null)
                    _ActionBtn(Icons.delete_outline, 'Eliminar', onDelete!,
                        color: AppTheme.error),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderImg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56, height: 56,
      color: AppTheme.surfaceContainerHigh,
      child: Icon(Icons.image_outlined, color: AppTheme.outline, size: 24),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn(this.icon, this.label, this.onTap,
      {this.color = AppTheme.primaryContainer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }
}
