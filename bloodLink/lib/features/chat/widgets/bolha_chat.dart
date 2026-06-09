import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Bolha individual de uma mensagem no chat.
/// [isUser] indica se a mensagem é de quem está a ver o ecrã (fica à direita).
class BolhaChat extends StatelessWidget {
  final String texto;
  final bool isUser;

  const BolhaChat({super.key, required this.texto, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
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