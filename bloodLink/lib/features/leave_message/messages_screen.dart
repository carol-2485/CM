import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'message_detail_screen.dart';

class MyMessagesScreen extends StatelessWidget {
  const MyMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Minhas Mensagens'),
        backgroundColor: AppColors.background,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('userId', isEqualTo: userId)
            //.orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final messages = snapshot.data!.docs;

          if (messages.isEmpty) {
            return const Center(
              child: Text(
                'Ainda não enviou nenhuma mensagem',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final data = msg.data() as Map<String, dynamic>;
              final isReplied = data['status'] == 'replied';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isReplied
                          ? Colors.green.shade100
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isReplied ? Icons.mark_email_read : Icons.mail_outline,
                      color: isReplied ? Colors.green : AppColors.primary,
                    ),
                  ),
                  title: Text(
                    data['subject'] ?? 'Sem assunto',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                  subtitle: Text(
                    isReplied ? 'Respondida' : 'À espera de resposta',
                    style: TextStyle(
                      fontSize: 12,
                      color: isReplied ? Colors.green : AppColors.textMuted,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessageDetailScreen(messageId: msg.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}