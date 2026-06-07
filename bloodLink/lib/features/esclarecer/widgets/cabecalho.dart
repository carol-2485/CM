import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/app_colors.dart';
import 'package:flutter_application_1/features/common/widgets/blood_drop.dart';


/// Título e subtítulo do ecrã de esclarecimento.
class CabecalhoEsclarecer extends StatelessWidget {
  const CabecalhoEsclarecer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            BloodDrop(size: 22),
            SizedBox(width: 8),
            Text(
              'Esclarecer Dúvidas',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary),
            ),
          ]),
          const SizedBox(height: 4),
          const Text(
            'Fale com um profissional de saúde',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}