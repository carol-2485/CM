import 'package:google_generative_ai/google_generative_ai.dart';

final _model = GenerativeModel(
  model: 'gemini-1.5-flash', 
  apiKey: '',
);

Future<String> _fetchAIResponse(String message) async {
  final response = await _model.generateContent([
    Content.text(message)
  ]);
  return response.text ?? 'Sem resposta';
}