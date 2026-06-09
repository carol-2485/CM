import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../common/services/chat_service.dart';
import 'widgets/bolha_chat.dart';

/// Ecrã de chat universal, usado tanto pelo lado do utilizador
/// como pelo lado do centro de saúde.
class ChatScreen extends StatefulWidget {
  /// ID do chat já existente (criado em EscolherCentroChatScreen ou na lista).
  final String chatId;

  /// Nome a mostrar no AppBar (nome do centro para o user, nome do user para o centro).
  final String tituloAppBar;

  /// 'user' ou 'centro' — define de que lado da conversa está quem está a ver o ecrã.
  final String tipo;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.tituloAppBar,
    required this.tipo,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatService.marcarComoLido(widget.chatId, widget.tipo);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _msgCtrl.text.trim();
    if (texto.isEmpty) return;
    _msgCtrl.clear();
    await _chatService.enviarMensagem(widget.chatId, texto, widget.tipo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.tituloAppBar),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.mensagensStream(widget.chatId),
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
                    // A mensagem é "minha" se o tipo dela coincide com o tipo de quem vê
                    final souEu = data['tipo'] == widget.tipo;
                    return BolhaChat(
                      texto: data['texto'] ?? '',
                      isUser: souEu,
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