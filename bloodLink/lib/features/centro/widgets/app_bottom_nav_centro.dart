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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: AppColors.surface,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.event_available_outlined), label: 'Vagas'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
        onTap: (i) {
          if (i == currentIndex) return;
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutesCentro.home);
            case 1:
              Navigator.pushNamed(context, AppRoutesCentro.gerirVagas);
            case 2:
              Navigator.pushNamed(context, AppRoutesCentro.pedidos);
            case 3:
              Navigator.pushReplacementNamed(context, AppRoutesCentro.perfil);
          }
        },
      ),
    );
  }
}
