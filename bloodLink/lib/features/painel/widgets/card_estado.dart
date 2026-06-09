// lib/features/painel/widgets/card_estado.dart
//
// Cartão que apresenta o estado actual de aptidão do doador.
// Quando apto, mostra um badge verde. Quando inapto, apresenta
// um botão para realizar o questionário de avaliação.

import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_routes.dart';

/// Cartão do painel com o estado de aptidão do utilizador.
class CardEstado extends StatelessWidget {
  /// Indica se o utilizador está apto para realizar doações.
  final bool estaApto;

  const CardEstado({super.key, required this.estaApto});

  @override
  Widget build(BuildContext context) {
    final corEstado = estaApto ? const Color(0xFF22C55E) : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone de estado
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: corEstado.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              estaApto
                  ? Icons.check_circle_outline_rounded
                  : Icons.pending_actions_rounded,
              color: corEstado,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Texto e acção
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESTADO ACTUAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),

                // Badge de apto ou botão para avaliar
                if (estaApto)
                  _BadgeApto(cor: corEstado)
                else
                  _BotaoAvaliar(
                    aoPremir: () => Navigator.pushNamed(
                        context, AppRoutesUser.questionario),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge verde a indicar que o utilizador está apto para doar.
class _BadgeApto extends StatelessWidget {
  final Color cor;
  const _BadgeApto({required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: cor),
          const SizedBox(width: 4),
          Text(
            'Apto para doar',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão para o utilizador realizar o questionário de aptidão.
class _BotaoAvaliar extends StatelessWidget {
  final VoidCallback aoPremir;
  const _BotaoAvaliar({required this.aoPremir});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: aoPremir,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
      ),
      child: const Text(
        'Avaliar aptidão',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
