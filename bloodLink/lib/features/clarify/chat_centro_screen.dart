// lib/features/clarify/chat_centro_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../common/services/chat_service.dart';
import '../common/widgets/app_bottom_nav.dart';
import '../common/widgets/blood_drop.dart';

class ChatCentroScreen extends StatefulWidget {
  final String centroId;
  final String centroNome;
  const ChatCentroScreen({super.key, required this.centroId, required this.centroNome});

  @override
  State<ChatCentroScreen> createState() => _ChatCentroScreenState();
}

class _ChatCentroScreenState extends State<ChatCentroScreen> {
  final _chatService = ChatService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _chatId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final id = await _chatService.obterOuCriarChat(widget.centroId);
    if (mounted) setState(() => _chatId = id);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _msgCtrl.text.trim();
    if (texto.isEmpty || _chatId == null) return;
    _msgCtrl.clear();
    await _chatService.enviarMensagem(_chatId!, texto, 'user');
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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.centroNome,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent)),
            const Text('Chat com o centro', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatId == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : StreamBuilder<QuerySnapshot>(
                    stream: _chatService.mensagensStream(_chatId!),
                    builder: (ctx, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      final msgs = snap.data!.docs;
                      if (msgs.isEmpty) {
                        return Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.border),
                            const SizedBox(height: 12),
                            const Text('Inicie a conversa com o centro de saúde.',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          ]),
                        );
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                      return ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: msgs.length,
                        itemBuilder: (ctx, i) {
                          final d = msgs[i].data() as Map<String, dynamic>;
                          final isUser = d['tipo'] == 'user';
                          final hora = d['criadaEm'] != null
                              ? (d['criadaEm'] as Timestamp).toDate()
                              : DateTime.now();
                          return _Bubble(
                            texto: d['texto'] ?? '',
                            isUser: isUser,
                            hora: '${hora.hour.toString().padLeft(2,'0')}:${hora.minute.toString().padLeft(2,'0')}',
                          );
                        },
                      );
                    },
                  ),
          ),
          // Input
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
                    hintText: 'Escreva a sua dúvida...',
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
                  maxLines: null,
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
    );
  }
}

class _Bubble extends StatelessWidget {
  final String texto;
  final bool isUser;
  final String hora;
  const _Bubble({required this.texto, required this.isUser, required this.hora});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(texto, style: TextStyle(
              fontSize: 14, color: isUser ? Colors.white : AppColors.textPrimary, height: 1.4)),
          const SizedBox(height: 4),
          Text(hora, style: TextStyle(
              fontSize: 10, color: isUser ? Colors.white60 : AppColors.textMuted)),
        ]),
      ),
    );
  }
}
