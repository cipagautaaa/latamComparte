import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../widgets/common_widgets.dart';
import '../../core/services/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final usuario = authProv.usuario;

    String rolLabel = 'Usuario';
    Color rolColor = Colors.grey;
    IconData rolIcon = Icons.person;

    if (authProv.isSuperadmin) {
      rolLabel = 'Superadministrador';
      rolColor = AppColors.primary;
      rolIcon = Icons.admin_panel_settings;
    } else if (authProv.isAdminPais) {
      rolLabel = 'Admin País';
      rolColor = AppColors.secondary;
      rolIcon = Icons.manage_accounts;
    } else if (authProv.isEditor) {
      rolLabel = 'Editor';
      rolColor = AppColors.info;
      rolIcon = Icons.edit_note;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header con gradiente
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            usuario?.nombre.isNotEmpty == true
                                ? usuario!.nombre[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        usuario?.nombre ?? 'Usuario',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(rolIcon, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              rolLabel,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Info de cuenta
                  _InfoCard(
                    titulo: 'Información de cuenta',
                    icono: Icons.account_circle_outlined,
                    items: [
                      _InfoItem(
                        label: 'Nombre completo',
                        valor: usuario?.nombre ?? '-',
                        icono: Icons.person_outline,
                      ),
                      _InfoItem(
                        label: 'Correo electrónico',
                        valor: usuario?.correo ?? '-',
                        icono: Icons.email_outlined,
                      ),
                      _InfoItem(
                        label: 'Rol en el sistema',
                        valor: rolLabel,
                        icono: rolIcon,
                        colorValor: rolColor,
                      ),
                      if (usuario?.paisNombre != null)
                        _InfoItem(
                          label: 'País asignado',
                          valor: '${AppHelpers.getPaisFlag(usuario?.paisCodigo ?? '')} ${usuario!.paisNombre!}',
                          icono: Icons.flag_outlined,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Permisos
                  _InfoCard(
                    titulo: 'Permisos',
                    icono: Icons.security_outlined,
                    items: [
                      _PermisoItem(
                        label: 'Ver todos los países',
                        permitido: authProv.isSuperadmin,
                      ),
                      _PermisoItem(
                        label: 'Gestionar noticias',
                        permitido: true,
                      ),
                      _PermisoItem(
                        label: 'Gestionar testimonios',
                        permitido: true,
                      ),
                      _PermisoItem(
                        label: 'Ver solicitudes',
                        permitido: authProv.isSuperadmin || authProv.isAdminPais,
                      ),
                      _PermisoItem(
                        label: 'Eliminar contenido',
                        permitido: authProv.puedeEliminar,
                      ),
                      _PermisoItem(
                        label: 'Gestionar portales',
                        permitido: authProv.isSuperadmin,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botón cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmarCerrarSesion(context, authProv),
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarCerrarSesion(BuildContext context, AuthProvider authProv) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Cerrar sesión',
      message: '¿Estás seguro de que deseas cerrar sesión?',
      confirmLabel: 'Cerrar sesión',
      esDestructivo: true,
    );
    if (confirm && context.mounted) {
      await authProv.logout();
      if (context.mounted) context.go('/login');
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> items;

  const _InfoCard({required this.titulo, required this.icono, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icono, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;
  final Color? colorValor;

  const _InfoItem({
    required this.label,
    required this.valor,
    required this.icono,
    this.colorValor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icono, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorValor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermisoItem extends StatelessWidget {
  final String label;
  final bool permitido;

  const _PermisoItem({required this.label, required this.permitido});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            permitido ? Icons.check_circle : Icons.cancel_outlined,
            size: 18,
            color: permitido ? AppColors.success : Colors.grey.shade400,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: permitido ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
