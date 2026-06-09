import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../common/chat/chat_screen.dart';
import '../common/services/chat_service.dart';
import '../common/widgets/app_bottom_nav.dart';

class EscolherCentroChatScreen extends StatelessWidget {
  const EscolherCentroChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Escolher Centro'),
        backgroundColor: AppColors.background,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('centros').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final centros = snapshot.data!.docs;

          if (centros.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum centro disponível',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: centros.length,
            itemBuilder: (context, index) {
              final centro = centros[index];
              final data = centro.data() as Map<String, dynamic>;
              final nome = data['nome'] ?? 'Centro';
              final morada = data['morada'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.local_hospital,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                  subtitle: Text(
                    morada,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _abrirChat(context, centro.id, nome),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Future<void> _abrirChat(
    BuildContext context,
    String centroId,
    String centroNome,
  ) async {
    final chatId = await ChatService().obterOuCriarChat(centroId);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          tituloAppBar: centroNome,
          tipo: 'user',
        ),
      ),
    );
  }
}