import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/app_colors.dart';
import 'package:flutter_application_1/features/questionario/questionario_screen.dart';

/// Campo de texto para o nome do medicamento (aparece quando o utilizador
/// indica que usa medicação contínua).
class CampoMedicamento extends StatelessWidget {
  final TextEditingController ctrl;
  const CampoMedicamento({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          decoration: decoracaoCampo(
            'Nome do medicamento *',
            icone: Icons.medication_outlined,
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Indique o nome do medicamento' : null,
        ),
        const SizedBox(height: 6),
        // Aviso informativo sobre a verificação via OpenFDA
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
