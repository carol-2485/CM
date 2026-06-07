// lib/features/chat_centro/chat_resposta_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../common/services/chat_service.dart';
import '../centro/widgets/app_bottom_nav_centro.dart';

class ChatRespostaCentroScreen extends StatefulWidget {
  final String chatId;
  final String nomeUser;
  const ChatRespostaCentroScreen({super.key, required this.chatId, required this.nomeUser});

  @override
  State<ChatRespostaCentroScreen> createState() => _ChatRespostaCentroScreenState();
}

class _ChatRespostaCentroScreenState extends State<ChatRespostaCentroScreen> {
  final _chatService = ChatService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _msgCtrl.text.trim();
    if (texto.isEmpty) return;
    _msgCtrl.clear();
    await _chatService.enviarMensagem(widget.chatId, texto, 'centro');
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.nomeUser, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent)),
          const Text('Doador', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.mensagensStream(widget.chatId),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                final msgs = snap.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                if (msgs.isEmpty) {
                  return const Center(child: Text('Sem mensagens ainda.',
                      style: TextStyle(color: AppColors.textMuted)));
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: msgs.length,
                  itemBuilder: (ctx, i) {
                    final d = msgs[i].data() as Map<String, dynamic>;
                    // Do ponto de vista do centro: 'centro' é o lado direito
                    final isCentro = d['tipo'] == 'centro';
                    final hora = d['criadaEm'] != null
                        ? (d['criadaEm'] as Timestamp).toDate()
                        : DateTime.now();
                    return Align(
                      alignment: isCentro ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCentro ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isCentro ? const Radius.circular(16) : const Radius.circular(4),
                            bottomRight: isCentro ? const Radius.circular(4) : const Radius.circular(16),
                          ),
                          border: isCentro ? null : Border.all(color: AppColors.border),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(d['texto'] ?? '', style: TextStyle(
                              fontSize: 14, color: isCentro ? Colors.white : AppColors.textPrimary, height: 1.4)),
                          const SizedBox(height: 4),
                          Text('${hora.hour.toString().padLeft(2,'0')}:${hora.minute.toString().padLeft(2,'0')}',
                              style: TextStyle(fontSize: 10,
                                  color: isCentro ? Colors.white60 : AppColors.textMuted)),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: 'Responder...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.inputBg,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _enviar(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _enviar,
                child: Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavCentro(currentIndex: 0),
    );
  }
}
