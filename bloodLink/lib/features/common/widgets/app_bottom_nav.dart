// lib/features/common/widgets/app_bottom_nav.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_routes.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        onTap: (i) {
          if (i == currentIndex) return;
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutesUser.home);
            case 1:
              Navigator.pushNamed(context, AppRoutesUser.centros);
            case 2:
              Navigator.pushNamed(context, AppRoutesUser.painel);
            case 3:
              Navigator.pushNamed(context, AppRoutesUser.esclarecer);
            case 4:
              Navigator.pushNamed(context, AppRoutesUser.perfil);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Agendar'),
          BottomNavigationBarItem(icon: Icon(Icons.water_drop_outlined), label: 'Painel'),
          BottomNavigationBarItem(icon: Icon(Icons.headset_mic_outlined), label: 'Apoio'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}
