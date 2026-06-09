// lib/features/centro/widgets/app_bottom_nav_centro.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_routes.dart';

class AppBottomNavCentro extends StatelessWidget {
  final int currentIndex;
  const AppBottomNavCentro({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItemCentro(
                icon: Icons.home_outlined,
                iconActivo: Icons.home_rounded,
                label: 'Início',
                activo: currentIndex == 0,
                onTap: () {
                  if (currentIndex != 0) {
                    Navigator.pushReplacementNamed(context, AppRoutesCentro.home);
                  }
                },
              ),
              _NavItemCentro(
                icon: Icons.event_available_outlined,
                iconActivo: Icons.event_available_rounded,
                label: 'Vagas',
                activo: currentIndex == 1,
                onTap: () {
                  if (currentIndex != 1) {
                    Navigator.pushNamed(context, AppRoutesCentro.gerirVagas);
                  }
                },
              ),
              _NavItemCentro(
                icon: Icons.list_alt_outlined,
                iconActivo: Icons.list_alt_rounded,
                label: 'Pedidos',
                activo: currentIndex == 2,
                onTap: () {
                  if (currentIndex != 2) {
                    Navigator.pushNamed(context, AppRoutesCentro.pedidos);
                  }
                },
              ),
              _NavItemCentro(
                icon: Icons.person_outline_rounded,
                iconActivo: Icons.person_rounded,
                label: 'Perfil',
                activo: currentIndex == 3,
                onTap: () {
                  if (currentIndex != 3) {
                    Navigator.pushReplacementNamed(context, AppRoutesCentro.perfil);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemCentro extends StatelessWidget {
  final IconData icon;
  final IconData iconActivo;
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _NavItemCentro({
    required this.icon,
    required this.iconActivo,
    required this.label,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: activo ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                activo ? iconActivo : icon,
                color: activo ? AppColors.primary : AppColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: activo ? FontWeight.w700 : FontWeight.w400,
                color: activo ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
