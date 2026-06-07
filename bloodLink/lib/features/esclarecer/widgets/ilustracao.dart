import 'package:flutter_application_1/constants/app_colors.dart';

import 'package:flutter/material.dart';

/// Ilustração decorativa da secção de apoio.
class IlustraoApoio extends StatelessWidget {
  const IlustraoApoio({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.medical_information_outlined,
          size: 60,
          color: AppColors.primary,
        ),
      ),
    );
  }
}