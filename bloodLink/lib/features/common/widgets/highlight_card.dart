// lib/features/common/widgets/highlight_card.dart
//
// Cartão de destaque com fundo na cor primária.
// Utilizado para apresentar informações importantes com ícone,
// título e subtítulo sobre fundo vermelho escuro.

import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Cartão de destaque com fundo na cor primária da aplicação.
///
/// Suporta widget personalizado no lado direito [trailing]
/// e callback [onTap] para navegação.
class HighlightCard extends StatelessWidget {
  /// Ícone principal do cartão.
  final IconData icon;

  /// Título em destaque.
  final String title;

  /// Subtítulo ou descrição.
  final String subtitle;

  /// Widget personalizado à direita (substitui a seta de navegação).
  final Widget? trailing;

  /// Callback de navegação (null desactiva o gesto).
  final VoidCallback? onTap;

  const HighlightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Ícone com fundo translúcido
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),

            // Título e subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing ou seta por defeito
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
