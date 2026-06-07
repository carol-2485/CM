// lib/features/notificacoes/notificacoes_screen.dart
//
// Ecrã de notificações do utilizador.
// Múltiplas mensagens do mesmo chat agrupadas numa só notificação com badge contador.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../chat_user/chat_centro_screen.dart';
import '../common/services/notificacao_service.dart';
import '../common/widgets/app_bottom_nav.dart';

class NotificacoesScreen extends StatelessWidget {
  const NotificacoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notificações',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.accent)),
        actions: [
          TextButton(
            onPressed: NotificacaoService.marcarTodasComoLidas,
            child: const Text('Marcar todas',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificacaoService.notificacoesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final notificacoes = snapshot.data ?? [];
          if (notificacoes.isEmpty) return const _EstadoVazioNotificacoes();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notificacoes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) =>
                CartaoNotificacao(notificacao: notificacoes[i]),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

// ── Estado vazio ──────────────────────────────────────────────────────────────

class _EstadoVazioNotificacoes extends StatelessWidget {
  const _EstadoVazioNotificacoes();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('Sem notificações',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent)),
          const SizedBox(height: 4),
          const Text('As suas notificações aparecerão aqui',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ── Cartão de notificação ─────────────────────────────────────────────────────

/// Cartão individual de notificação com hover animado.
/// Para notificações de mensagem com múltiplas mensagens não lidas,
/// mostra um badge com a contagem no canto direito.
class CartaoNotificacao extends StatefulWidget {
  final Map<String, dynamic> notificacao;
  const CartaoNotificacao({super.key, required this.notificacao});

  @override
  State<CartaoNotificacao> createState() => _CartaoNotificacaoState();
}

class _CartaoNotificacaoState extends State<CartaoNotificacao> {
  bool _hover = false;

  Map<String, dynamic> get _n => widget.notificacao;

  IconData get _icone {
    switch (_n['tipo']) {
      case 'mensagem': return Icons.chat_bubble_rounded;
      case 'agendamento_confirmado': return Icons.calendar_month_rounded;
      case 'agendamento_pendente': return Icons.pending_actions_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color get _cor {
    switch (_n['tipo']) {
      case 'mensagem': return const Color(0xFF3B82F6);
      case 'agendamento_confirmado': return const Color(0xFF22C55E);
      case 'agendamento_pendente': return const Color(0xFFF59E0B);
      default: return AppColors.primary;
    }
  }

  String _formatarHora(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = (timestamp as Timestamp).toDate();
      final d = DateTime.now().difference(dt);
      if (d.inMinutes < 60) return 'há ${d.inMinutes} min';
      if (d.inHours < 24) return 'há ${d.inHours}h';
      return DateFormat('d MMM', 'pt_PT').format(dt);
    } catch (_) { return ''; }
  }

  /// Marca como lida e navega para o destino correcto.
  Future<void> _aoPremir() async {
    if (!(_n['lida'] as bool? ?? false)) {
      NotificacaoService.marcarComoLida(_n['id'] as String);
    }
    if (!mounted) return;

    if (_n['tipo'] == 'mensagem') {
      final chatId = _n['chatId'] as String?;
      if (chatId == null) return;

      // chatId formato: userId_centroId
      final partes = chatId.split('_');
      final centroId = partes.length >= 2 ? partes.last : chatId;

      String centroNome = 'Centro de Saúde';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('centros').doc(centroId).get();
        centroNome = doc.data()?['nome'] as String? ?? centroNome;
      } catch (_) {}

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) =>
              ChatCentroScreen(centroId: centroId, centroNome: centroNome),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final naoLida = !(_n['lida'] as bool? ?? false);
    final eMensagem = _n['tipo'] == 'mensagem';
    final contagem = (_n['contagem'] as int?) ?? 1;

    final corFundo = _hover
        ? _cor.withOpacity(naoLida ? 0.10 : 0.05)
        : (naoLida ? _cor.withOpacity(0.05) : AppColors.surface);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _aoPremir,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: corFundo,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hover
                  ? _cor.withOpacity(0.5)
                  : (naoLida ? _cor.withOpacity(0.25) : AppColors.border),
              width: (naoLida || _hover) ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _cor.withOpacity(_hover ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icone, color: _cor, size: 22),
              ),
              const SizedBox(width: 12),

              // Título + mensagem + link hover
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _n['titulo'] as String? ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: naoLida
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        Text(
                          _formatarHora(_n['criadaEm']),
                          style: TextStyle(
                            fontSize: 11,
                            color: _hover ? _cor : AppColors.textMuted,
                            fontWeight: _hover
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _n['mensagem'] as String? ?? '',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.4),
                    ),
                    // "Abrir conversa →" em hover para mensagens
                    if (eMensagem && _hover) ...[
                      const SizedBox(height: 5),
                      Row(children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 12, color: _cor),
                        const SizedBox(width: 4),
                        Text('Abrir conversa',
                            style: TextStyle(
                                fontSize: 11,
                                color: _cor,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_forward_rounded,
                            size: 11, color: _cor),
                      ]),
                    ],
                  ],
                ),
              ),

              // Badge de contagem (ponto simples ou número)
              if (naoLida) ...[
                const SizedBox(width: 8),
                _BadgeContagem(contagem: contagem, cor: _cor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge de contagem ─────────────────────────────────────────────────────────

/// Ponto simples quando há 1 mensagem; badge numerado quando há mais.
class _BadgeContagem extends StatelessWidget {
  final int contagem;
  final Color cor;
  const _BadgeContagem({required this.contagem, required this.cor});

  @override
  Widget build(BuildContext context) {
    if (contagem <= 1) {
      return Container(
        width: 9, height: 9,
        decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: cor, borderRadius: BorderRadius.circular(20)),
      child: Text(
        '$contagem',
        style: const TextStyle(
            fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}
