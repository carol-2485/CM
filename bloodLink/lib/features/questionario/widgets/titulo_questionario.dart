import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/app_colors.dart';
import 'package:flutter_application_1/features/common/widgets/blood_drop.dart';

/// Título do questionário com ícone de gota.
class TituloQuestionario extends StatelessWidget {
  const TituloQuestionario({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BloodDrop(size: 28),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Questionário de\nAptidão para Doação',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}