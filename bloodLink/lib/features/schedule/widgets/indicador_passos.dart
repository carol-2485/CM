// lib/features/schedule/widgets/indicador_passos.dart
//
// Widget do indicador de progresso em passos (stepper) usado nos ecrãs
// de agendamento de doação de sangue.

import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Indicador visual de progresso com 3 passos.
class IndicadorPassos extends StatelessWidget {
  /// Passo actualmente activo (1, 2 ou 3).
  final int passoActual;

  const IndicadorPassos({super.key, required this.passoActual});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Passo(numero: 1, activo: passoActual >= 1, concluido: passoActual > 1),
          _Linha(activa: passoActual > 1),
          _Passo(numero: 2, activo: passoActual >= 2, concluido: passoActual > 2),
          _Linha(activa: passoActual > 2),
          _Passo(numero: 3, activo: passoActual >= 3, concluido: false),
        ],
      ),
    );
  }
}

/// Círculo numerado para cada passo.
class _Passo extends StatelessWidget {
  final int numero;
  final bool activo;
  final bool concluido;

  const _Passo({
    required this.numero,
    required this.activo,
    required this.concluido,
  });

  @override
  Widget build(BuildContext context) {
    final destacado = activo || concluido;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: destacado ? AppColors.primary : AppColors.surface,
        border: Border.all(
          color: destacado ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          '$numero',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: destacado ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Linha horizontal entre passos.
class _Linha extends StatelessWidget {
  final bool activa;
  const _Linha({required this.activa});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 1.5,
      color: activa ? AppColors.primary : AppColors.border,
    );
  }
}
