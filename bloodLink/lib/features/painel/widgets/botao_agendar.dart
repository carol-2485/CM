// lib/features/painel/widgets/botao_agendar.dart
//
// Botão de destaque para iniciar um novo agendamento de doação.
// Apresentado no painel apenas quando o utilizador está apto.

import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Botão primário de agendamento com sombra e ícone.
class BotaoAgendar extends StatelessWidget {
  /// Callback executado ao premir o botão.
  final VoidCallback onTap;

  const BotaoAgendar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Agendar Nova Doação',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
