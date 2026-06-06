import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class MessageSection extends StatelessWidget {
  final String label;
  final String content;
  final bool highlight;

  const MessageSection({
    super.key,
    required this.label,
    required this.content,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: highlight ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlight ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            content,
            style: TextStyle(
              color: highlight ? Colors.white : AppColors.accent,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}