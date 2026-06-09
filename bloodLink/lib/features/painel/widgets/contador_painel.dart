// lib/features/painel/widgets/contador_painel.dart
//
// Widget de contador estatístico usado no cabeçalho do painel do doador.
// Apresenta um valor numérico em destaque com um rótulo descritivo.

import 'package:flutter/material.dart';

/// Contador de estatística com fundo translúcido para o cabeçalho do painel.
///
/// Usado para mostrar: doações realizadas, sangue doado, vidas salvas.
class ContadorPainel extends StatelessWidget {
  /// Valor a apresentar em destaque (ex: "5", "2.3L").
  final String valor;

  /// Rótulo descritivo abaixo do valor (pode ter quebra de linha).
  final String rotulo;

  const ContadorPainel({
    super.key,
    required this.valor,
    required this.rotulo,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            // Valor numérico em destaque
            Text(
              valor,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),

            // Rótulo descritivo
            Text(
              rotulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
