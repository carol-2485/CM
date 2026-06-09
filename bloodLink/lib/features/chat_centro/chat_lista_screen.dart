import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../chat/chat_screen.dart';
import '../common/services/chat_service.dart';

class ChatListaCentroScreen extends StatelessWidget {
  const ChatListaCentroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final centroId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mensagens'),
        backgroundColor: AppColors.background,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ChatService().chatsDoCentro(centroId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(
              child: Text(
                'Sem conversas',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;
              final userId = data['userId'] as String;
              final ultimaMensagem = data['ultimaMensagem'] ?? '';
              final unread = (data['unreadByCentro'] ?? 0) as int;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, userSnap) {
                  String nomeUser = 'Utilizador';
                  if (userSnap.hasData) {
                    final userData =
                        userSnap.data!.data() as Map<String, dynamic>?;
                    nomeUser = (userData?['nome'] as String?) ?? 'Utilizador';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.person,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        nomeUser,
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
                          builder: (_) => ChatScreen(
                            chatId: chat.id,
                            tituloAppBar: nomeUser,
                            tipo: 'centro',
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
    );
  }
}