// lib/features/clarify/clarify_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../chat/chat_ia_screen.dart';
import '../common/widgets/app_bottom_nav.dart';
import '../common/widgets/blood_drop.dart';
import 'escolher_centro_chat_screen.dart';

class EsclarecerScreen extends StatefulWidget {
  const EsclarecerScreen({super.key});
  @override
  State<EsclarecerScreen> createState() => _EsclarecerScreenState();
}

class _EsclarecerScreenState extends State<EsclarecerScreen> {
  int _selected = -1;

  final _opcoes = [
    _Opcao(Icons.phone_rounded, 'Videochamada / Chamada',
        'Fale directamente com um profissional'),
    _Opcao(Icons.smart_toy_outlined, 'Chat com IA',
        'Pergunte ao assistente de saúde'),
    _Opcao(Icons.chat_bubble_outline_rounded, 'Mensagem para o Centro',
        'Envie uma dúvida ao centro de saúde'),
  ];

  Future<void> _iniciar() async {
    switch (_selected) {
      case 0:
        const number = '351932044469';
        final url = Uri.parse(
            'https://wa.me/$number?text=Olá, gostaria de esclarecer uma dúvida sobre doação de sangue.');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
        break;
      case 1:
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatIAScreen()));
        break;
      case 2:
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EscolherCentroChatScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                const BloodDrop(size: 22),
                const SizedBox(width: 8),
                const Text('Esclarecer Dúvidas',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ]),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Fale com um profissional de saúde',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ),
            const SizedBox(height: 24),

            // Imagem / ilustração
            Center(
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.medical_information_outlined,
                    size: 60, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 28),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Como deseja ser atendido?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent)),
            ),
            const SizedBox(height: 14),

            // Opções
            ...List.generate(_opcoes.length, (i) {
              final o = _opcoes[i];
              final sel = _selected == i;
              return GestureDetector(
                onTap: () => setState(() => _selected = i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary.withOpacity(0.06) : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary.withOpacity(0.15) : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(o.icon, color: sel ? AppColors.primary : AppColors.textMuted, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o.titulo, style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: sel ? AppColors.primary : AppColors.accent)),
                      Text(o.subtitulo, style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                    ])),
                    if (sel) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                  ]),
                ),
              );
            }),

            const Spacer(),

            // Botão iniciar
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _selected == -1 ? null : _iniciar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.border,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Iniciar conversa',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

class _Opcao {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  const _Opcao(this.icon, this.titulo, this.subtitulo);
}
