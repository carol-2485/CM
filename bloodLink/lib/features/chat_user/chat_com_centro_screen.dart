import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../common/services/chat_service.dart';
import 'widgets/bolha_chat.dart';

class ChatCentroScreen extends StatefulWidget {
  final String centroId;
  final String centroNome;

  const ChatCentroScreen({
    super.key,
    required this.centroId,
    required this.centroNome,
  });

  @override
  State<ChatCentroScreen> createState() => _ChatCentroScreenState();
}

class _ChatCentroScreenState extends State<ChatCentroScreen> {
  final _chatService = ChatService();
  final _msgCtrl = TextEditingController();
  String? _chatId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final id = await _chatService.obterOuCriarChat(widget.centroId);
    if (!mounted) return;
    setState(() => _chatId = id);
    _chatService.marcarComoLido(id, 'user');
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _msgCtrl.text.trim();
    if (texto.isEmpty || _chatId == null) return;
    _msgCtrl.clear();
    await _chatService.enviarMensagem(_chatId!, texto, 'user');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.centroNome),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatId == null
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _chatService.mensagensStream(_chatId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        );
                      }
                      final msgs = snapshot.data!.docs;

                      if (msgs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Sem mensagens ainda',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: msgs.length,
                        itemBuilder: (context, index) {
                          final data = msgs[index].data() as Map<String, dynamic>;
                          return BolhaChat(
                            texto: data['texto'] ?? '',
                            isUser: data['tipo'] == 'user',
                          );
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Escreva uma mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _enviar,
                  icon: const Icon(Icons.send),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}