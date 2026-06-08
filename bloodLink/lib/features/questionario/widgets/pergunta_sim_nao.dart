import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/app_colors.dart';

/// Par de radio buttons "Sim / Não" para uma pergunta fechada.
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
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Radio<bool>(
                  value: true,
                  groupValue: valor,
                  onChanged: (v) => onChange(v!)),
              const Text('Sim',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(width: 24),
              Radio<bool>(
                  value: false,
                  groupValue: valor,
                  onChanged: (v) => onChange(v!)),
              const Text('Não',
                  style: TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}