import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/app_colors.dart';

/// Diálogo com o resultado da avaliação de aptidão.
class DialogoResultado extends StatelessWidget {
  final bool apto;
  final String? motivo;
  final VoidCallback onClose;

  const DialogoResultado({
    super.key,
    required this.apto,
    required this.motivo,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cor = apto ? const Color(0xFF22C55E) : AppColors.error;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone de resultado
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            child: Icon(
              apto ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),

          // Mensagem principal
          Text(
            apto ? 'Está apto para doar sangue!' : 'Não está apto de momento.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          // Motivo (se inapto)
          if (motivo != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                motivo!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cor, height: 1.4),
              ),
            ),
          ],

          // Nota adicional para inaptos
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
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onClose,
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
