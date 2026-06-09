import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/chat_ia/services/gemini_service.dart';
import '../../constants/app_colors.dart';
import '../common/chat/widgets/bolha_chat.dart';

class ChatIAScreen extends StatefulWidget {
  const ChatIAScreen({super.key});

  @override
  State<ChatIAScreen> createState() => _ChatIAScreenState();
}

class _ChatIAScreenState extends State<ChatIAScreen> {
  final _controller = TextEditingController();
  final _gemini = GeminiService();
  final List<Map<String, dynamic>> _mensagens = [];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _loading) return;

    setState(() {
      _mensagens.add({'texto': texto, 'isUser': true});
      _loading = true;
    });
    _controller.clear();

    try {
      final resposta = await _gemini.enviarMensagem(texto);
      setState(() {
        _mensagens.add({'texto': resposta, 'isUser': false});
      });
    } catch (e) {
      setState(() {
        _mensagens.add({'texto': 'Erro ao obter resposta', 'isUser': false});
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assistente BloodLink'),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mensagens.length,
              itemBuilder: (context, index) {
                final msg = _mensagens[index];
                return BolhaChat(
                  texto: msg['texto'],
                  isUser: msg['isUser'],
                );
              },
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Escreve a tua pergunta...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loading ? null : _enviar,
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