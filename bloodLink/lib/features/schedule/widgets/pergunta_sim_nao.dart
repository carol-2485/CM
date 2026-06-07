// lib/features/schedule/widgets/pergunta_sim_nao.dart
//
// Widget reutilizável para perguntas de resposta binária (Sim/Não)
// utilizadas no questionário de aptidão para doação de sangue.

import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Apresenta uma pergunta com opções de resposta Sim/Não via Radio buttons.
class PerguntaSimNao extends StatelessWidget {
  /// Texto da pergunta a apresentar ao utilizador.
  final String pergunta;

  /// Valor actual da resposta (null se ainda não respondido).
  final bool? valor;

  /// Callback invocado quando o utilizador altera a resposta.
  final void Function(bool) aoMudar;

  const PerguntaSimNao({
    super.key,
    required this.pergunta,
    required this.valor,
    required this.aoMudar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texto da pergunta
          Text(
            pergunta,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Opções Sim/Não
          Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: valor,
                activeColor: AppColors.primary,
                onChanged: (v) => aoMudar(v!),
              ),
              const Text('Sim', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 24),
              Radio<bool>(
                value: false,
                groupValue: valor,
                activeColor: AppColors.primary,
                onChanged: (v) => aoMudar(v!),
              ),
              const Text('Não', style: TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
