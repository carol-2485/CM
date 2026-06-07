import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../constants/app_colors.dart';

class ChatIAScreen extends StatefulWidget {
  const ChatIAScreen({super.key});

  @override
  State<ChatIAScreen> createState() => _ChatIAScreenState();
}

class _ChatIAScreenState extends State<ChatIAScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <({String text, bool isUser})>[];
  late final ChatSession _chat;
  bool _isLoading = false;

  // Sugestões rápidas de perguntas
  static const _sugestoes = [
    'Posso doar sangue com gripe?',
    'Quanto tempo após tatuar posso dar sangue?',
    'Que tipo de sangue é universal?',
    'Com que frequência posso fazer doações?',
  ];

  @override
  void initState() {
    super.initState();
    _chat = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: dotenv.env['GEMINI_API_KEY']!,
      systemInstruction: Content.system(
        'És um assistente especializado em doação de sangue do BloodLink. '
        'Responde sempre em português de Portugal, de forma clara, empática e concisa. '
        'Foca-te em questões relacionadas com doação de sangue, elegibilidade, saúde e o processo de doação.',
      ),
    ).startChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? textoFixo]) async {
    final text = textoFixo ?? _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add((text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(text));
      setState(() => _messages.add((text: response.text ?? 'Sem resposta', isUser: false)));
    } catch (e) {
      setState(() => _messages.add((text: 'Ocorreu um erro. Tente novamente.', isUser: false)));
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final semMensagens = _messages.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assistente BloodLink',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
              Text('Disponível agora',
                  style: TextStyle(fontSize: 10, color: Color(0xFF22C55E), fontWeight: FontWeight.w500)),
            ],
          ),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: semMensagens
              ? _EstadoInicial(sugestoes: _sugestoes, onSugestao: _sendMessage)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) return const _TypingIndicator();
                    final msg = _messages[index];
                    return _BolhaMensagem(texto: msg.text, isUser: msg.isUser);
                  },
                ),
        ),
        _InputArea(
          controller: _controller,
          isLoading: _isLoading,
          onSend: () => _sendMessage(),
        ),
      ]),
    );
  }
}

// ── Estado inicial / ecrã vazio ──────────────────────────────────────────────
class _EstadoInicial extends StatelessWidget {
  final List<String> sugestoes;
  final void Function(String) onSugestao;
  const _EstadoInicial({required this.sugestoes, required this.onSugestao});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(children: [
        const SizedBox(height: 20),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 40),
        ),
        const SizedBox(height: 16),
        const Text('Olá! Sou o assistente BloodLink',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text(
          'Estou aqui para responder às tuas dúvidas sobre doação de sangue. Escolhe uma pergunta ou escreve a tua.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Perguntas frequentes',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.textMuted, letterSpacing: 0.5)),
        ),
        const SizedBox(height: 10),
        ...sugestoes.map((s) => _SugestaoChip(texto: s, onTap: () => onSugestao(s))),
      ]),
    );
  }
}

class _SugestaoChip extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;
  const _SugestaoChip({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(Icons.help_outline_rounded, color: AppColors.primary.withOpacity(0.7), size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(texto,
              style: const TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w500))),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}

// ── Bolha de mensagem ────────────────────────────────────────────────────────
class _BolhaMensagem extends StatelessWidget {
  final String texto;
  final bool isUser;
  const _BolhaMensagem({required this.texto, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14),
            ),
          ],
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser ? null : Border.all(color: AppColors.border),
            ),
            child: Text(
              texto,
              style: TextStyle(
                color: isUser ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Indicador de digitação ───────────────────────────────────────────────────
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          _Ponto(delay: 0),
          SizedBox(width: 4),
          _Ponto(delay: 200),
          SizedBox(width: 4),
          _Ponto(delay: 400),
        ]),
      ),
    );
  }
}

class _Ponto extends StatefulWidget {
  final int delay;
  const _Ponto({required this.delay});
  @override
  State<_Ponto> createState() => _PontoState();
}

class _PontoState extends State<_Ponto> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: Interval(widget.delay / 600, 1.0, curve: Curves.easeInOut)));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6, height: 6,
        decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle),
      ),
    );
  }
}

// ── Área de input ────────────────────────────────────────────────────────────
class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  const _InputArea({required this.controller, required this.isLoading, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.5))),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Escreve a tua pergunta...',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading ? null : onSend,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isLoading ? AppColors.border : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLoading ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                color: Colors.white, size: 20,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
