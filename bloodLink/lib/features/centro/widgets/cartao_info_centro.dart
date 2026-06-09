// lib/features/centro/widgets/cartao_info_centro.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class LinhaInfoCentro {
  final String rotulo;
  final String valor;
  final IconData icone;
  final Color corIcone;

  const LinhaInfoCentro({
    required this.rotulo,
    required this.valor,
    required this.icone,
    required this.corIcone,
  });
}

class CartaoInfoCentro extends StatelessWidget {
  final List<LinhaInfoCentro> linhas;
  const CartaoInfoCentro({super.key, required this.linhas});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: linhas.asMap().entries.map((entry) {
          final i = entry.key;
          final linha = entry.value;
          final ultima = i == linhas.length - 1;
          return _LinhaInfoWidget(linha: linha, ultima: ultima);
        }).toList(),
      ),
    );
  }
}

class _LinhaInfoWidget extends StatelessWidget {
  final LinhaInfoCentro linha;
  final bool ultima;
  const _LinhaInfoWidget({required this.linha, required this.ultima});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: ultima
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: linha.corIcone.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(linha.icone, color: linha.corIcone, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(linha.rotulo,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(linha.valor,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent)),
            ],
          ),
        ),
      ]),
    );
  }
}
