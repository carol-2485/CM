import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'reply_message_screen.dart';
import 'widgets/app_bottom_nav_centro.dart';

class CentroMessagesScreen extends StatelessWidget {
  const CentroMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final centerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mensagens Recebidas'),
        backgroundColor: AppColors.background,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('centerId', isEqualTo: centerId)
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
                'Sem mensagens recebidas',
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
              final isPending = data['status'] == 'pending';

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
                      color: isPending
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPending ? Icons.mail_outline : Icons.mark_email_read,
                      color: isPending ? AppColors.primary : Colors.green,
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
                    isPending ? 'Pendente' : 'Respondida',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPending ? AppColors.primary : Colors.green,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReplyMessageScreen(messageId: msg.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavCentro(currentIndex: 3),
    );
  }
}