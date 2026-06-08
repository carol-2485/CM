// lib/features/schedule/widgets/campo_data_doacao.dart
//
// Campo de selecção de data da última doação de sangue.

import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Campo de data (somente leitura) com selector de calendário.
class CampoDataDoacao extends StatelessWidget {
  final TextEditingController ctrl;

  const CampoDataDoacao({super.key, required this.ctrl});

  /// Abre o selector de data e formata o resultado no controlador.
  Future<void> _abrirSelectorData(BuildContext context) async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 90)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (dataEscolhida != null) {
      ctrl.text =
          '${dataEscolhida.day.toString().padLeft(2, '0')}/${dataEscolhida.month.toString().padLeft(2, '0')}/${dataEscolhida.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      onTap: () => _abrirSelectorData(context),
      decoration: InputDecoration(
        hintText: 'Data da última doação',
        suffixIcon: const Icon(
          Icons.calendar_month_outlined,
          color: AppColors.primary,
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
      ),
    );
  }
}
