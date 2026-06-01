import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';

class AppBottomNavCentro extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavCentro({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      backgroundColor: AppColors.surface,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Vagas'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Pedidos'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
      onTap: (index) {
        if (index == currentIndex) return; // já está nessa página

        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, AppRoutesCentro.home);
            break;
          case 1:
            //Navigator.pushReplacementNamed(context, AppRoutesCentro.gerirSlots);
            break;
          case 2:
            //Navigator.pushReplacementNamed(context, AppRoutesCentro.pedidos);
            break;
          case 3:
            Navigator.pushReplacementNamed(context, AppRoutesCentro.perfil);
            break;
        }
      },
    );
  }
}