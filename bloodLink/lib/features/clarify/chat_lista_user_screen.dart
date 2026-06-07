import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../common/services/chat_service.dart';
import '../common/widgets/app_bottom_nav.dart';
import 'chat_centro_screen.dart';

class ChatListaUserScreen extends StatelessWidget {
  const ChatListaUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final chatService = ChatService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mensagens'),
        backgroundColor: AppColors.background,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatService.chatsDoUtilizador(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: AppColors.border,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Ainda não iniciou nenhuma conversa.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;
              final centroId = data['centroId'] as String;
              final ultimaMensagem = (data['ultimaMensagem'] as String?) ?? '';
              final unread = (data['unreadByUser'] ?? 0) as int;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('centros')
                    .doc(centroId)
                    .get(),
                builder: (context, centroSnap) {
                  String centroNome = 'A carregar...';
                  if (centroSnap.hasData) {
                    final centroData =
                        centroSnap.data!.data() as Map<String, dynamic>?;
                    centroNome = (centroData?['nome'] as String?) ?? 'Centro';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.background,
                        child: Icon(
                          Icons.local_hospital,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        centroNome,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                      subtitle: Text(
                        ultimaMensagem.isEmpty
                            ? 'Sem mensagens ainda'
                            : ultimaMensagem,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      trailing: unread > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.chevron_right,
                              color: AppColors.textMuted,
                            ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatCentroScreen(
                            centroId: centroId,
                            centroNome: centroNome,
                          ),
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}