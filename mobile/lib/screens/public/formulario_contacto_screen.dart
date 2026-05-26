import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common_widgets.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';

class FormularioContactoScreen extends StatefulWidget {
  const FormularioContactoScreen({super.key});

  @override
  State<FormularioContactoScreen> createState() => _FormularioContactoScreenState();
}

class _FormularioContactoScreenState extends State<FormularioContactoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _finalidadCtrl = TextEditingController();

  List<Pais> _paises = [];
  String? _paisSeleccionado;
  bool _enviando = false;
  bool _enviado = false;
  bool _cargandoPaises = true;

  @override
  void initState() {
    super.initState();
    _cargarPaises();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
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
    if (_paisSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu país'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      await ApiService.instance.crearSolicitudPublica({
        'nombre': _nombreCtrl.text.trim(),
        'correo': _correoCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'finalidad': _finalidadCtrl.text.trim(),
        'pais': _paisSeleccionado,
      });

      if (mounted) setState(() { _enviado = true; _enviando = false; });
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -30, top: -30,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20, bottom: -20,
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text(
                            'Contáctanos',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Queremos acompañarte en tu camino',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _enviado
                ? _PantallaExito()
                : _FormularioContenido(
                    formKey: _formKey,
                    nombreCtrl: _nombreCtrl,
                    correoCtrl: _correoCtrl,
                    telefonoCtrl: _telefonoCtrl,
                    finalidadCtrl: _finalidadCtrl,
                    paises: _paises,
                    paisSeleccionado: _paisSeleccionado,
                    cargandoPaises: _cargandoPaises,
                    enviando: _enviando,
                    onPaisChanged: (v) => setState(() => _paisSeleccionado = v),
                    onEnviar: _enviar,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PantallaExito extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, size: 60, color: AppColors.success),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Mensaje enviado!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hemos recibido tu solicitud de contacto. Nuestro equipo se comunicará contigo a la brevedad.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              onPressed: () => context.go('/login'),
              label: 'Ir al inicio',
              icon: Icons.home_outlined,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Enviar otra solicitud'),
          ),
        ],
      ),
    );
  }
}

class _FormularioContenido extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreCtrl;
  final TextEditingController correoCtrl;
  final TextEditingController telefonoCtrl;
  final TextEditingController finalidadCtrl;
  final List<Pais> paises;
  final String? paisSeleccionado;
  final bool cargandoPaises;
  final bool enviando;
  final ValueChanged<String?> onPaisChanged;
  final VoidCallback onEnviar;

  const _FormularioContenido({
    required this.formKey,
    required this.nombreCtrl,
    required this.correoCtrl,
    required this.telefonoCtrl,
    required this.finalidadCtrl,
    required this.paises,
    required this.paisSeleccionado,
    required this.cargandoPaises,
    required this.enviando,
    required this.onPaisChanged,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: enviando,
      child: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Completa el formulario y nos pondremos en contacto contigo para brindarte información sobre nuestros programas.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _Section(
                titulo: 'Datos personales',
                children: [
                  AppTextField(
                    controller: nombreCtrl,
                    label: 'Nombre completo *',
                    hint: 'Tu nombre y apellido',
                    prefixIcon: Icons.person_outline,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (v.length < 3) return 'Mínimo 3 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: correoCtrl,
                    label: 'Correo electrónico *',
                    hint: 'tucorreo@ejemplo.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      final emailReg = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailReg.hasMatch(v)) return 'Ingresa un correo válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: telefonoCtrl,
                    label: 'Teléfono / WhatsApp *',
                    hint: '+57 300 123 4567',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (v.length < 7) return 'Teléfono inválido';
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _Section(
                titulo: 'Tu solicitud',
                children: [
                  // Dropdown de países cargado desde el backend
                  cargandoPaises
                      ? const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ))
                      : DropdownButtonFormField<String>(
                          value: paisSeleccionado,
                          decoration: InputDecoration(
                            labelText: 'País *',
                            prefixIcon: const Icon(Icons.flag_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          hint: const Text('Selecciona tu país'),
                          items: paises.map((p) {
                            final flag = _flag(p.codigo);
                            return DropdownMenuItem(
                              value: p.id,
                              child: Text('$flag ${p.nombre}'),
                            );
                          }).toList(),
                          onChanged: onPaisChanged,
                          validator: (v) => (v == null || v.isEmpty) ? 'Selecciona tu país' : null,
                        ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: finalidadCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: '¿En qué podemos ayudarte? *',
                      hintText: 'Cuéntanos brevemente lo que necesitas...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (v.length < 10) return 'Por favor sé más específico';
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onPressed: enviando ? null : onEnviar,
                  label: enviando ? 'Enviando...' : 'Enviar solicitud',
                  icon: Icons.send_outlined,
                ),
              ),
              const SizedBox(height: 12),

              Center(
                child: TextButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login, size: 16),
                  label: const Text('¿Eres administrador? Inicia sesión'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _flag(String codigo) {
    switch (codigo) {
      case 'CO': return '🇨🇴';
      case 'CL': return '🇨🇱';
      case 'EC': return '🇪🇨';
      default: return '🌎';
    }
  }
}

class _Section extends StatelessWidget {
  final String titulo;
  final List<Widget> children;

  const _Section({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}
