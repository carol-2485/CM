import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../common/widgets/message_section.dart';

class MessageDetailScreen extends StatelessWidget {
  final String messageId;

  const MessageDetailScreen({super.key, required this.messageId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mensagem'),
        backgroundColor: AppColors.background,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('messages')
            .doc(messageId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final hasReply = data['reply'] != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MessageSection(
                  label: 'ASSUNTO',
                  content: data['subject'] ?? '—',
                ),
                const SizedBox(height: 16),
                MessageSection(
                  label: 'A SUA MENSAGEM',
                  content: data['text'] ?? '—',
                ),
                const SizedBox(height: 16),
                if (hasReply)
                  MessageSection(
                    label: 'RESPOSTA',
                    content: data['reply'],
                    highlight: true,
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.access_time, color: AppColors.textMuted),
                        SizedBox(width: 12),
                        Text(
                          'À espera de resposta...',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}