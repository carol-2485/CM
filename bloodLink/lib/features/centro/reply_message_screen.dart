import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/common/widgets/message_section.dart';
import '../../constants/app_colors.dart';

class ReplyMessageScreen extends StatefulWidget {
  final String messageId;

  const ReplyMessageScreen({super.key, required this.messageId});

  @override
  State<ReplyMessageScreen> createState() => _ReplyMessageScreenState();
}

class _ReplyMessageScreenState extends State<ReplyMessageScreen> {
  final _replyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final reply = _replyCtrl.text.trim();
    if (reply.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escreva uma resposta')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      final centerId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.messageId)
          .update({
            'reply': reply,
            'repliedBy': centerId,
            'status': 'replied',
            'repliedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resposta enviada!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Responder'),
        backgroundColor: AppColors.background,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('messages')
            .doc(widget.messageId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final alreadyReplied = data['status'] == 'replied';

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
                  label: 'MENSAGEM DO UTILIZADOR',
                  content: data['text'] ?? '—',
                ),
                const SizedBox(height: 16),
                if (alreadyReplied)
                  MessageSection(
                    label: 'A SUA RESPOSTA',
                    content: data['reply'],
                    highlight: true,
                  )
                else ...[
                  const Text(
                    'A SUA RESPOSTA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _replyCtrl,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Escreva a sua resposta...',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _sendReply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _sending
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Enviar Resposta',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}