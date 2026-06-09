// lib/features/schedule/widgets/pergunta_sim_nao.dart
//
// Widget reutilizável para perguntas de resposta binária (Sim/Não)
// utilizadas no questionário de aptidão para doação de sangue.

import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Apresenta uma pergunta com opções de resposta Sim/Não via Radio buttons.
class PerguntaSimNao extends StatelessWidget {
  final String pergunta;
  final bool? valor;
  final void Function(bool) onChange;

  const PerguntaSimNao({
    super.key,
    required this.pergunta,
    required this.valor,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pergunta,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Radio<bool>(
                value: true,
                // ignore: deprecated_member_use
                groupValue: valor,
                fillColor: WidgetStateProperty.all(AppColors.primary),
                // ignore: deprecated_member_use
                onChanged: (v) => onChange(v!),
              ),
              const Text('Sim', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 24),
              Radio<bool>(
                value: false,
                // ignore: deprecated_member_use
                groupValue: valor,
                fillColor: WidgetStateProperty.all(AppColors.primary),
                // ignore: deprecated_member_use
                onChanged: (v) => onChange(v!),
              ),
              const Text('Não', style: TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
