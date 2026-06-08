import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/questionario/questionario_screen.dart';

class CampoDataDoacao extends StatelessWidget {
  final TextEditingController ctrl;
  const CampoDataDoacao({super.key,required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      onTap: () async {
        final escolhida = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 90)),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (escolhida != null) {
          ctrl.text =
              '${escolhida.day.toString().padLeft(2, '0')}/${escolhida.month.toString().padLeft(2, '0')}/${escolhida.year}';
        }
      },
      decoration: decoracaoCampo(
        'Data da última doação',
        icone: Icons.calendar_month_outlined,
        ehSufixo: true,
      ),
    );
  }
}