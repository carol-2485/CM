// lib/features/painel/widgets/card_agendamento.dart
//
// Cartão que apresenta o próximo agendamento de doação do utilizador.
// Mostra o centro, hora, data e estado (confirmado/pendente).

import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Cartão do painel com informação do próximo agendamento.
///
/// Quando não há agendamento, apresenta um botão para agendar.
class CardAgendamento extends StatelessWidget {
  /// Dados do próximo agendamento ou null se não existir.
  final Map<String, dynamic>? proximoAgendamento;

  /// Callback para navegar para o ecrã de agendamento.
  final VoidCallback aoAgendar;

  const CardAgendamento({
    super.key,
    required this.proximoAgendamento,
    required this.aoAgendar,
  });

  /// Converte chave YYYY-MM-DD para formato DD/MM/AAAA.
  String _formatarDataKey(String chave) {
    final partes = chave.split('-');
    if (partes.length != 3) return chave;
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final temAgendamento = proximoAgendamento != null;
    final confirmado =
        temAgendamento && proximoAgendamento!['estado'] == 'confirmado';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone de calendário
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Conteúdo textual
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRÓXIMO AGENDAMENTO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),

                if (temAgendamento) ...[
                  // Nome do centro
                  Text(
                    proximoAgendamento!['centroNome'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Hora, data e badge de estado
                  Row(
                    children: [
                      Text(
                        proximoAgendamento!['hora'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatarDataKey(
                            proximoAgendamento!['dataKey'] as String),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _BadgeEstado(confirmado: confirmado),
                    ],
                  ),
                ] else
                  const Text(
                    'Sem agendamentos futuros',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),

          // Botão de agendar quando não há agendamento
          if (!temAgendamento)
            TextButton(
              onPressed: aoAgendar,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text(
                'Agendar',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Badge colorido que indica o estado do agendamento.
class _BadgeEstado extends StatelessWidget {
  final bool confirmado;
  const _BadgeEstado({required this.confirmado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: confirmado
            ? const Color(0xFF22C55E).withOpacity(0.12)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        confirmado ? 'Confirmado' : 'Pendente',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: confirmado
              ? const Color(0xFF22C55E)
              : const Color(0xFFE65100),
        ),
      ),
    );
  }
}
