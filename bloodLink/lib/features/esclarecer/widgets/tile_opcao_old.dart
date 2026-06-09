import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/app_colors.dart';

/// Dados de uma opção de atendimento.
class OpcaoAtendimento {
  final IconData icone;
  final String titulo;
  final String subtitulo;

  const OpcaoAtendimento(this.icone, this.titulo, this.subtitulo);
}

/// Tile de opção de atendimento seleccionável.
class TileOpcao extends StatelessWidget {
  final OpcaoAtendimento opcao;
  final bool seleccionado;
  final VoidCallback onSelected;

  const TileOpcao({
    super.key,
    required this.opcao,
    required this.seleccionado,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: seleccionado
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? AppColors.primary : AppColors.border,
            width: seleccionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Ícone
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: seleccionado
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                opcao.icone,
                color: seleccionado ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opcao.titulo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: seleccionado
                          ? AppColors.primary
                          : AppColors.accent,
                    ),
                  ),
                  Text(
                    opcao.subtitulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Check de selecção
            if (seleccionado)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
