// lib/features/schedule/widgets/dialogo_resultado_aptidao.dart
//
// Diálogo modal que apresenta o resultado da avaliação de aptidão
// para doação de sangue.

import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Diálogo que apresenta se o utilizador está apto ou inapto para doar.
class DialogoResultadoAptidao extends StatelessWidget {
  /// Indica se o utilizador está apto para doação.
  final bool apto;

  /// Motivo de inaptidão (null quando apto).
  final String? motivo;

  /// Callback executado quando o utilizador prime o botão de continuar.
  final VoidCallback onContinuar;

  const DialogoResultadoAptidao({
    super.key,
    required this.apto,
    required this.onContinuar,
    this.motivo,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone de resultado
          _IconeResultado(apto: apto),
          const SizedBox(height: 16),

          // Mensagem principal
          Text(
            apto ? 'Está apto para doar sangue!' : 'Não está apto de momento.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          // Motivo de inaptidão
          if (motivo != null) ...[
            const SizedBox(height: 10),
            _CartaoMotivo(motivo: motivo!, apto: apto),
          ],

          // Nota de rodapé para casos de inaptidão
          if (!apto) ...[
            const SizedBox(height: 8),
            const Text(
              'Para mais informações contacte um profissional de saúde ou o IPST.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
      actions: [
        // Botão de acção
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onContinuar,
            child: Text(
              apto ? 'Ver centros de doação' : 'Voltar ao início',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Círculo com ícone de check ou X conforme o resultado.
class _IconeResultado extends StatelessWidget {
  final bool apto;
  const _IconeResultado({required this.apto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: apto ? AppColors.success : AppColors.error,
        shape: BoxShape.circle,
      ),
      child: Icon(
        apto ? Icons.check_rounded : Icons.close_rounded,
        color: Colors.white,
        size: 36,
      ),
    );
  }
}

/// Cartão com fundo colorido a apresentar o motivo da decisão.
class _CartaoMotivo extends StatelessWidget {
  final String motivo;
  final bool apto;
  const _CartaoMotivo({required this.motivo, required this.apto});

  @override
  Widget build(BuildContext context) {
    final cor = apto ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        motivo,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: cor, height: 1.4),
      ),
    );
  }
}
