import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/app_colors.dart';

/// Botão de verificação de aptidão.
class BotaoVerificar extends StatelessWidget {
  final bool aVerificar;
  final VoidCallback onClick;

  const BotaoVerificar({
    super.key,
    required this.aVerificar,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: aVerificar ? null : onClick,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: aVerificar
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Verificar Aptidão',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
      ),
    );
  }
}