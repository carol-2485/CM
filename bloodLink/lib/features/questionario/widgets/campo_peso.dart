import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/questionario/questionario_screen.dart';

/// Campo de texto para o peso corporal do utilizador.
class CampoPeso extends StatelessWidget {
  final TextEditingController ctrl;
  const CampoPeso({super.key,required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: decoracaoCampo('Peso (Kg)*'),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Campo obrigatório';
        final p = double.tryParse(v.replaceAll(',', '.'));
        if (p == null || p < 50) return 'Peso mínimo é 50 kg';
        return null;
      },
    );
  }
}
