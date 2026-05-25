import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/app_colors.dart';

class ChatIAScreen extends StatefulWidget {
  const ChatIAScreen({super.key});

  @override
  State<ChatIAScreen> createState() => _ChatIAScreenState();
}

class _ChatIAScreenState extends State<ChatIAScreen> {
  final _controller = TextEditingController();
  final _messages = <({String text, bool isUser})>[];
  late final ChatSession _chat;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chat = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: dotenv.env['GEMINI_API_KEY']!,
      systemInstruction: Content.system(
        'És um assistente de saúde. Responde sempre em português de Portugal.',
      ),
    ).startChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add((text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();

    try {
      final response = await _chat.sendMessage(Content.text(text));
      setState(() => _messages.add((
        text: response.text ?? 'Sem resposta',
        isUser: false,
      )));
    } catch (e) {
      setState(() => _messages.add((text: 'Erro: $e', isUser: false)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat com IA')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: msg.isUser ? AppColors.primary : AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const CircularProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Escreve a tua pergunta...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
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