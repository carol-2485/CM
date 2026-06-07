// lib/features/centro/widgets/botao_terminar_sessao_centro.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class BotaoTerminarSessaoCentro extends StatelessWidget {
  final VoidCallback onTap;
  const BotaoTerminarSessaoCentro({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text(
              'Terminar sessão',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}
