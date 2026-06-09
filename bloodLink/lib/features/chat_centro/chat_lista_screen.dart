// lib/features/chat_centro/chat_lista_screen.dart
//
// Lista de conversas do centro de saúde com os utilizadores.
// Ordenada por mensagem mais recente, com indicação visual
// de mensagens por ler (negrito + badge + borda colorida).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../common/services/chat_service.dart';
import '../common/widgets/blood_drop.dart';
import '../centro/widgets/app_bottom_nav_centro.dart';
import 'chat_resposta_screen.dart';

/// Ecrã de lista de conversas do centro de saúde.
class ChatListaCentroScreen extends StatefulWidget {
  const ChatListaCentroScreen({super.key});

  @override
  State<ChatListaCentroScreen> createState() => _ChatListaCentroScreenState();
}

class _ChatListaCentroScreenState extends State<ChatListaCentroScreen> {
  final _chatService = ChatService();
  String? _centroId;

  @override
  void initState() {
    super.initState();
    _resolverCentroId();
  }

  /// Resolve o ID do documento do centro a partir do UID do utilizador autenticado.
  Future<void> _resolverCentroId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('centros')
        .doc(uid)
        .get();

    if (doc.exists) {
      if (mounted) setState(() => _centroId = uid);
    } else {
      final q = await FirebaseFirestore.instance
          .collection('centros')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty && mounted) {
        setState(() => _centroId = q.docs.first.id);
      }
    }
  }

  /// Formata o timestamp para apresentação (ex: "14:32", "Ontem", "3 Jun").
  String _formatarHora(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = (timestamp as Timestamp).toDate().toLocal();
      final agora = DateTime.now();
      final hoje = DateTime(agora.year, agora.month, agora.day);
      final diaMsg = DateTime(dt.year, dt.month, dt.day);

      if (diaMsg == hoje) return DateFormat('HH:mm').format(dt);
      if (diaMsg == hoje.subtract(const Duration(days: 1))) return 'Ontem';
      return DateFormat('d MMM', 'pt_PT').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const BloodDrop(size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Mensagens',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lista de chats em tempo real
          Expanded(
            child: _centroId == null
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _chatService.chatsDoCentro(_centroId!),
                    builder: (ctx, snap) {
                      // Mostra loading apenas no primeiro carregamento
                      if (snap.connectionState == ConnectionState.waiting &&
                          !snap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        );
                      }
                      if (snap.hasError) {
                        return const Center(
                          child: Text('Erro ao carregar mensagens.',
                              style: TextStyle(color: AppColors.textMuted)),
                        );
                      }

                      // Ordena no cliente por ultimaHora descendente
                      final chats =
                          List<QueryDocumentSnapshot>.from(
                              snap.data?.docs ?? []);
                      chats.sort((a, b) {
                        final da =
                            (a.data() as Map)['ultimaHora'] as Timestamp?;
                        final db =
                            (b.data() as Map)['ultimaHora'] as Timestamp?;
                        if (da == null && db == null) return 0;
                        if (da == null) return 1;
                        if (db == null) return -1;
                        return db.compareTo(da);
                      });

                      if (chats.isEmpty) {
                        return const Center(
                          child: Text(
                            'Sem mensagens de utilizadores.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: chats.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final dados =
                              chats[i].data() as Map<String, dynamic>;
                          final chatId = chats[i].id;
                          final userId = dados['userId'] as String? ?? '';
                          final naoLidas =
                              (dados['unreadByCentro'] ?? 0) as int;
                          final temNaoLidas = naoLidas > 0;

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .get(),
                            builder: (ctx2, userSnap) {
                              // Extrai o nome do utilizador
                              String nomeUser = 'Utilizador';
                              if (userSnap.hasData &&
                                  userSnap.data!.exists) {
                                final u = userSnap.data!.data()
                                    as Map<String, dynamic>;
                                nomeUser = u['nome'] as String? ??
                                    'Utilizador';
                              }

                              return _CartaoChat(
                                chatId: chatId,
                                nomeUser: nomeUser,
                                ultimaMensagem:
                                    dados['ultimaMensagem'] as String? ?? '',
                                hora: _formatarHora(dados['ultimaHora']),
                                naoLidas: naoLidas,
                                temNaoLidas: temNaoLidas,
                                aoPremir: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatRespostaCentroScreen(
                                      chatId: chatId,
                                      nomeUser: nomeUser,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavCentro(currentIndex: 0),
    );
  }
}

// ── Cartão de conversa ────────────────────────────────────────────────────────

/// Cartão individual de uma conversa na lista do centro.
/// Com hover animado — fundo e borda mudam ao passar o rato.
class _CartaoChat extends StatefulWidget {
  final String chatId;
  final String nomeUser;
  final String ultimaMensagem;
  final String hora;
  final int naoLidas;
  final bool temNaoLidas;
  final VoidCallback aoPremir;

  const _CartaoChat({
    required this.chatId,
    required this.nomeUser,
    required this.ultimaMensagem,
    required this.hora,
    required this.naoLidas,
    required this.temNaoLidas,
    required this.aoPremir,
  });

  @override
  State<_CartaoChat> createState() => _CartaoChatState();
}

class _CartaoChatState extends State<_CartaoChat> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final destacado = _hover || widget.temNaoLidas;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.aoPremir,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: destacado
                ? AppColors.primary.withValues(alpha: 0.06)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: destacado
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.border,
              width: destacado ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              _AvatarUtilizador(
                iniciais: widget.nomeUser.isNotEmpty
                    ? widget.nomeUser[0].toUpperCase()
                    : '?',
                temNaoLidas: widget.temNaoLidas || _hover,
              ),
              const SizedBox(width: 12),

              // Nome e última mensagem
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nomeUser,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: destacado
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: destacado
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.ultimaMensagem,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: destacado
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: destacado
                            ? AppColors.accent
                            : AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Hora + badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.hora,
                    style: TextStyle(
                      fontSize: 11,
                      color: destacado
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontWeight: destacado
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.temNaoLidas)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.naoLidas}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Icon(
                      _hover
                          ? Icons.arrow_forward_ios_rounded
                          : Icons.chevron_right,
                      color: _hover
                          ? AppColors.primary
                          : AppColors.textMuted,
                      size: _hover ? 14 : 18,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar circular com inicial do nome do utilizador.
class _AvatarUtilizador extends StatelessWidget {
  final String iniciais;
  final bool temNaoLidas;

  const _AvatarUtilizador({
    required this.iniciais,
    required this.temNaoLidas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: temNaoLidas
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: temNaoLidas
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          iniciais,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
