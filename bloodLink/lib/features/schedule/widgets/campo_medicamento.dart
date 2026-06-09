// lib/features/schedule/widgets/campo_medicamento.dart
//
// Campo de introdução do nome do medicamento, com aviso informativo
// sobre a verificação via OpenFDA API.

import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Campo de texto para o nome do medicamento com nota explicativa.
class CampoMedicamento extends StatelessWidget {
  final TextEditingController controlador;

  const CampoMedicamento({super.key, required this.controlador});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        // Campo de texto
        TextFormField(
          controller: controlador,
          decoration: InputDecoration(
            hintText: 'Nome do medicamento *',
            prefixIcon: const Icon(
              Icons.medication_outlined,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Indique o nome do medicamento' : null,
        ),
        const SizedBox(height: 6),

        // Nota informativa sobre a verificação
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'A app verifica o medicamento contra a lista do IPST e a OpenFDA API.',
                  style: TextStyle(fontSize: 11, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
