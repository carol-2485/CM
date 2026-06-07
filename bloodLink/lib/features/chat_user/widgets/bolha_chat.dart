import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class BolhaChat extends StatelessWidget {
  final String texto;
  final bool isUser;

  const BolhaChat({super.key, required this.texto, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.accent,
          ),
        ),
      ),
    );
  }
}