import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Serviço para interagir com o assistente IA (Gemini).
class GeminiService {
  late final ChatSession _chat;

  GeminiService() {
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

  /// Envia uma mensagem ao assistente e devolve a resposta.
  Future<String> enviarMensagem(String texto) async {
    final response = await _chat.sendMessage(Content.text(texto));
    return response.text ?? 'Sem resposta';
  }
}