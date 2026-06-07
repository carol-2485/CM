// lib/features/common/widgets/section_label.dart
//
// Rótulo de secção reutilizável.
// Apresenta um texto em maiúsculas com espaçamento de letras,
// usado para separar grupos de conteúdo nas páginas.

import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Rótulo de secção com estilo capitalizado e espaçamento de letras.
class SectionLabel extends StatelessWidget {
  /// Texto do rótulo (normalmente em maiúsculas).
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}
