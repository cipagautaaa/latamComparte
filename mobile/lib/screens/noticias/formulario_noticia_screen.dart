import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class FormularioNoticiaScreen extends StatefulWidget {
  final String? noticiaId;
  const FormularioNoticiaScreen({super.key, this.noticiaId});

  @override
  State<FormularioNoticiaScreen> createState() => _FormularioNoticiaScreenState();
}

class _FormularioNoticiaScreenState extends State<FormularioNoticiaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _resumenCtrl = TextEditingController();
  final _contenidoCtrl = TextEditingController();
  final _autorCtrl = TextEditingController();
  final _imagenCtrl = TextEditingController();

  String _estado = 'borrador';
  String? _paisId;
  List<Pais> _paises = [];
  bool _loading = false;
  bool _loadingData = false;

  bool get isEditing => widget.noticiaId != null;

  @override
  void initState() {
    super.initState();
    _cargarPaises();
    if (isEditing) _cargarNoticia();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _resumenCtrl.dispose();
    _contenidoCtrl.dispose();
    _autorCtrl.dispose();
    _imagenCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPaises() async {
    final auth = context.read<AuthProvider>();
    try {
      if (auth.isSuperadmin) {
        final data = await ApiService.instance.getPaises();
        setState(() {
          _paises = data;
        });
      } else {
        // Admin/editor solo puede usar su propio país
        final pais = auth.usuario?.paisAsignado;
        if (pais != null) {
          setState(() {
            _paises = [pais];
            _paisId = pais.id;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _cargarNoticia() async {
    setState(() => _loadingData = true);
    try {
      final data = await ApiService.instance.getNoticia(widget.noticiaId!);
      final noticia = Noticia.fromJson(data);
      _tituloCtrl.text = noticia.titulo;
      _resumenCtrl.text = noticia.resumen;
      _contenidoCtrl.text = noticia.contenido;
      _autorCtrl.text = noticia.autor;
      _imagenCtrl.text = noticia.imagenUrl ?? '';
      setState(() {
        _estado = noticia.estado;
        _paisId = noticia.pais?.id;
        _loadingData = false;
      });
    } catch (e) {
      setState(() => _loadingData = false);
    }
  }

  Future<void> _guardar({bool publicar = false}) async {
    if (!_formKey.currentState!.validate()) return;

    if (_paisId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un país'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _loading = true);
    final data = {
      'titulo': _tituloCtrl.text.trim(),
      'resumen': _resumenCtrl.text.trim(),
      'contenido': _contenidoCtrl.text.trim(),
      'autor': _autorCtrl.text.trim(),
      'imagen_url': _imagenCtrl.text.trim().isEmpty ? null : _imagenCtrl.text.trim(),
      'pais': _paisId,
      'estado': publicar ? 'publicado' : _estado,
    };

    try {
      if (isEditing) {
        await ApiService.instance.editarNoticia(widget.noticiaId!, data);
      } else {
        await ApiService.instance.crearNoticia(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Noticia actualizada' : 'Noticia creada'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: GradientAppBar(
        title: isEditing ? 'Editar noticia' : 'Nueva noticia',
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Sección básica ────────────────────────
                    _SectionCard(
                      title: 'Información básica',
                      children: [
                        AppTextField(
                          label: 'Título *',
                          hint: 'Ingresa el título de la noticia',
                          controller: _tituloCtrl,
                          validator: (v) => v!.isEmpty ? 'Título requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Resumen *',
                          hint: 'Breve descripción de la noticia',
                          controller: _resumenCtrl,
                          maxLines: 3,
                          validator: (v) => v!.isEmpty ? 'Resumen requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Autor *',
                          hint: 'Nombre del autor',
                          controller: _autorCtrl,
                          prefixIcon: const Icon(Icons.person_outline, color: AppTheme.outline),
                          validator: (v) => v!.isEmpty ? 'Autor requerido' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── Contenido ─────────────────────────────
                    _SectionCard(
                      title: 'Contenido',
                      children: [
                        AppTextField(
                          label: 'Contenido completo *',
                          hint: 'Escribe el contenido completo de la noticia...',
                          controller: _contenidoCtrl,
                          maxLines: 8,
                          validator: (v) => v!.isEmpty ? 'Contenido requerido' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── Imagen y país ─────────────────────────
                    _SectionCard(
                      title: 'Imagen y configuración',
                      children: [
                        AppTextField(
                          label: 'URL de imagen (opcional)',
                          hint: 'https://...',
                          controller: _imagenCtrl,
                          prefixIcon: const Icon(Icons.image_outlined, color: AppTheme.outline),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        // Selector de país
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('País *', style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceVariant,
                            )),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _paisId,
                              decoration: InputDecoration(
                                hintText: 'Selecciona el país',
                                prefixIcon: const Icon(Icons.public_outlined,
                                  color: AppTheme.outline),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: _paises.map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.nombre),
                              )).toList(),
                              onChanged: (v) => setState(() => _paisId = v),
                              validator: (v) => v == null ? 'Selecciona un país' : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Estado
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estado', style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceVariant,
                            )),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _EstadoToggle(
                                  label: 'Borrador',
                                  selected: _estado == 'borrador',
                                  color: AppTheme.borradorColor,
                                  onTap: () => setState(() => _estado = 'borrador'),
                                ),
                                const SizedBox(width: 8),
                                _EstadoToggle(
                                  label: 'Publicado',
                                  selected: _estado == 'publicado',
                                  color: AppTheme.publicadoColor,
                                  onTap: () => setState(() => _estado = 'publicado'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Botones de acción ─────────────────────
                    GradientButton(
                      label: isEditing ? 'Guardar cambios' : 'Publicar noticia',
                      icon: Icons.check_circle_outline,
                      onPressed: _loading ? null : () => _guardar(publicar: true),
                      isLoading: _loading,
                    ),
                    const SizedBox(height: 12),
                    if (!isEditing)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Guardar como borrador'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryContainer,
                          side: const BorderSide(color: AppTheme.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: _loading ? null : () => _guardar(publicar: false),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.onSurface,
            )),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _EstadoToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _EstadoToggle({
    required this.label, required this.selected,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}
