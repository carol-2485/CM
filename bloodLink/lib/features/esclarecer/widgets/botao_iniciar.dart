import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/app_colors.dart';

/// Botão de confirmação de início de atendimento.
class BotaoIniciar extends StatelessWidget {
  final bool activo;
  final VoidCallback onClick;

  const BotaoIniciar({super.key, required this.activo, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: activo ? onClick : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.border,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Text(
          'Iniciar conversa',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white),
        ),
      ),
    );
  }
}