// lib/features/home/widgets/status_card.dart
//
// Cartão de estado de aptidão para doação.
// Apresentado no ecrã inicial do utilizador, indica se está
// apto (verde "Válido") ou convida a avaliar a aptidão.

import 'package:flutter/material.dart';
import '../../../constants/app_routes.dart';
import '../../common/widgets/highlight_card.dart';

/// Cartão de estado de aptidão para doação de sangue.
///
/// Quando [isEligible] é verdadeiro, apresenta um badge verde "Válido".
/// Caso contrário, mostra um botão para preencher o questionário.
class StatusCard extends StatelessWidget {
  /// Indica se o utilizador está apto para realizar doações.
  final bool isEligible;

  const StatusCard({super.key, required this.isEligible});

  @override
  Widget build(BuildContext context) {
    if (isEligible) {
      // Utilizador apto — badge verde no lado direito
      return HighlightCard(
        icon: Icons.water_drop_rounded,
        title: 'Apto para Doar',
        subtitle: 'O SEU ESTADO',
        trailing: _BadgeValido(),
      );
    }

    // Utilizador sem avaliação — navega para o questionário
    return HighlightCard(
      icon: Icons.edit_rounded,
      title: 'Avaliar Aptidão',
      subtitle: 'Preencha o seguinte questionário',
      onTap: () => Navigator.pushNamed(context, AppRoutesUser.aptidao),
    );
  }
}

/// Badge verde "✓ Válido" para utilizadores aptos.
class _BadgeValido extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'Válido',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
