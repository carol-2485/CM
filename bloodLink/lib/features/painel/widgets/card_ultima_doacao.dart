// lib/features/painel/widgets/card_ultima_doacao.dart
//
// Cartão que apresenta a data da última doação de sangue realizada.
// Se o utilizador ainda não realizou nenhuma doação, apresenta
// uma mensagem informativa.

import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Cartão do painel com a informação da última doação realizada.
class CardUltimaDoacao extends StatelessWidget {
  /// Data da última doação no formato YYYY-MM-DD, ou null/vazio se inexistente.
  final dynamic dataUltimaDoacao;

  const CardUltimaDoacao({super.key, this.dataUltimaDoacao});

  /// Formata a chave de data (YYYY-MM-DD) para apresentação (DD/MM/AAAA).
  String _formatarData(String raw) {
    final partes = raw.split('-');
    return partes.length == 3
        ? '${partes[2]}/${partes[1]}/${partes[0]}'
        : raw;
  }

  @override
  Widget build(BuildContext context) {
    final temData = dataUltimaDoacao != null &&
        dataUltimaDoacao.toString().isNotEmpty;

    final textoData = temData
        ? _formatarData(dataUltimaDoacao.toString())
        : 'Ainda não realizou doações';

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
          // Ícone de histórico
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Rótulo e data
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ÚLTIMA DOAÇÃO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                textoData,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
