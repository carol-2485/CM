// lib/features/chat_centro/chat_lista_screen.dart
// Lista de conversas do centro
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../common/services/chat_service.dart';
import '../common/widgets/blood_drop.dart';
import '../centro/widgets/app_bottom_nav_centro.dart';
import 'chat_resposta_screen.dart';

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

  Future<void> _resolverCentroId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('centros').doc(uid).get();
    if (doc.exists) {
      if (mounted) setState(() => _centroId = uid);
    } else {
      final q = await FirebaseFirestore.instance
          .collection('centros').where('uid', isEqualTo: uid).limit(1).get();
      if (q.docs.isNotEmpty && mounted) setState(() => _centroId = q.docs.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const BloodDrop(size: 22),
              const SizedBox(width: 8),
              const Text('Mensagens', style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _centroId == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : StreamBuilder<QuerySnapshot>(
                    stream: _chatService.chatsDoCentro(_centroId!),
                    builder: (ctx, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      final chats = snap.data!.docs;
                      if (chats.isEmpty) {
                        return const Center(
                          child: Text('Sem mensagens de utilizadores.',
                              style: TextStyle(color: AppColors.textMuted)));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: chats.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final d = chats[i].data() as Map<String, dynamic>;
                          final chatId = chats[i].id;
                          final userId = d['userId'] as String? ?? '';
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                            builder: (ctx2, userSnap) {
                              final nomeUser = userSnap.hasData && userSnap.data!.exists
                                  ? (userSnap.data!.data() as Map<String, dynamic>)['nome'] ?? 'Utilizador'
                                  : 'Utilizador';
                              return GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => ChatRespostaCentroScreen(
                                    chatId: chatId,
                                    nomeUser: nomeUser,
                                  ),
                                )),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.person_outline, color: AppColors.primary, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(nomeUser, style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
                                      Text(d['ultimaMensagem'] ?? '',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ])),
                                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                                  ]),
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
