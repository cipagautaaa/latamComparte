import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../widgets/common_widgets.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';

class FormularioTestimonioScreen extends StatefulWidget {
  final String? testimonioId;
  const FormularioTestimonioScreen({super.key, this.testimonioId});

  @override
  State<FormularioTestimonioScreen> createState() => _FormularioTestimonioScreenState();
}

class _FormularioTestimonioScreenState extends State<FormularioTestimonioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _fotoCtrl = TextEditingController();
  final _testimonioCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();

  String? _paisSeleccionado;
  String _estado = 'borrador';
  bool _cargando = false;
  bool _cargandoInicial = false;
  List<Pais> _paises = [];
  Testimonio? _testimonioOriginal;

  bool get _esEdicion => widget.testimonioId != null;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargandoInicial = true);
    try {
      final authProv = context.read<AuthProvider>();
      final paises = await ApiService.instance.getPaisesPublico();
      
      if (_esEdicion) {
        final testimonio = await ApiService.instance.getTestimonio(widget.testimonioId!);
        _testimonioOriginal = testimonio;
        _nombreCtrl.text = testimonio.nombre;
        _fotoCtrl.text = testimonio.fotoUrl ?? '';
        _testimonioCtrl.text = testimonio.testimonio;
        _instagramCtrl.text = testimonio.instagramUrl ?? '';
        _facebookCtrl.text = testimonio.facebookUrl ?? '';
        _estado = testimonio.estado;
        _paisSeleccionado = testimonio.paisId;
      } else {
        // Pre-seleccionar país para admin_pais/editor
        if (authProv.puedeVerSoloPais && authProv.paisAsignadoId != null) {
          _paisSeleccionado = authProv.paisAsignadoId;
        }
      }

      setState(() {
        _paises = paises;
        _cargandoInicial = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _cargandoInicial = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _guardar({bool publicar = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_paisSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un país'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _cargando = true);

    final estado = publicar ? 'publicado' : _estado;

    final datos = {
      'nombre': _nombreCtrl.text.trim(),
      'foto_url': _fotoCtrl.text.trim(),
      'testimonio': _testimonioCtrl.text.trim(),
      'pais': _paisSeleccionado,
      'estado': estado,
      if (_instagramCtrl.text.trim().isNotEmpty) 'instagram_url': _instagramCtrl.text.trim(),
      if (_facebookCtrl.text.trim().isNotEmpty) 'facebook_url': _facebookCtrl.text.trim(),
    };

    try {
      if (_esEdicion) {
        await ApiService.instance.editarTestimonio(widget.testimonioId!, datos);
      } else {
        await ApiService.instance.crearTestimonio(datos);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_esEdicion ? 'Testimonio actualizado' : 'Testimonio creado'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _fotoCtrl.dispose();
    _testimonioCtrl.dispose();
    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: _esEdicion ? 'Editar Testimonio' : 'Nuevo Testimonio',
      ),
      body: _cargandoInicial
          ? const Center(child: CircularProgressIndicator())
          : LoadingOverlay(
              isLoading: _cargando,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Datos principales
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Información principal',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    )),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _nombreCtrl,
                              label: 'Nombre completo *',
                              hint: 'Nombre de la persona',
                              prefixIcon: Icons.person_outline,
                              validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              controller: _fotoCtrl,
                              label: 'URL de foto *',
                              hint: 'https://...',
                              prefixIcon: Icons.image_outlined,
                              keyboardType: TextInputType.url,
                              validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                            ),
                            const SizedBox(height: 12),
                            // Preview foto
                            if (_fotoCtrl.text.isNotEmpty)
                              Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _fotoCtrl.text,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Testimonio
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Testimonio',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    )),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _testimonioCtrl,
                              maxLines: 6,
                              decoration: InputDecoration(
                                labelText: 'Texto del testimonio *',
                                hintText: 'Comparte la historia de éxito...',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // País y Estado
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Configuración',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    )),
                            const SizedBox(height: 16),
                            // Selector de país
                            DropdownButtonFormField<String>(
                              value: _paisSeleccionado,
                              decoration: InputDecoration(
                                labelText: 'País *',
                                prefixIcon: const Icon(Icons.flag_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              items: _paises.map((p) {
                                return DropdownMenuItem(
                                  value: p.id,
                                  child: Row(
                                    children: [
                                      Text(AppHelpers.getPaisFlag(p.codigo)),
                                      const SizedBox(width: 8),
                                      Text(p.nombre),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: authProv.puedeVerSoloPais ? null : (v) => setState(() => _paisSeleccionado = v),
                              validator: (v) => v == null ? 'Selecciona un país' : null,
                            ),
                            const SizedBox(height: 12),
                            // Estado
                            Text('Estado de publicación',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    )),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'borrador', label: Text('Borrador'), icon: Icon(Icons.edit_outlined, size: 16)),
                                ButtonSegment(value: 'publicado', label: Text('Publicado'), icon: Icon(Icons.check_circle_outline, size: 16)),
                                ButtonSegment(value: 'despublicado', label: Text('Oculto'), icon: Icon(Icons.visibility_off_outlined, size: 16)),
                              ],
                              selected: {_estado},
                              onSelectionChanged: (s) => setState(() => _estado = s.first),
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) return AppColors.primary;
                                  return null;
                                }),
                                foregroundColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) return Colors.white;
                                  return AppColors.textSecondary;
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Redes sociales
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Redes sociales',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        )),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('Opcional',
                                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _instagramCtrl,
                              label: 'Instagram',
                              hint: 'https://instagram.com/...',
                              prefixIcon: Icons.camera_alt_outlined,
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              controller: _facebookCtrl,
                              label: 'Facebook',
                              hint: 'https://facebook.com/...',
                              prefixIcon: Icons.facebook_outlined,
                              keyboardType: TextInputType.url,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _cargando ? null : () => _guardar(publicar: false),
                            icon: const Icon(Icons.save_outlined),
                            label: Text(_esEdicion ? 'Guardar cambios' : 'Guardar borrador'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GradientButton(
                            onPressed: _cargando ? null : () => _guardar(publicar: true),
                            label: 'Publicar',
                            icon: Icons.publish_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
