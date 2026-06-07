// lib/features/esclarecer/esclarecer_screen.dart
//
// Ecrã de apoio ao utilizador para esclarecer dúvidas sobre doação de sangue.
// Oferece três modalidades: chamada WhatsApp, chat com IA (Gemini)
// e mensagem directa para o centro de saúde.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../chat_ia/chat_ia_screen.dart';
import '../common/widgets/app_bottom_nav.dart';
import '../chat_user/escolher_centro_chat_screen.dart';
import 'widgets/botao_iniciar.dart';
import 'widgets/cabecalho.dart';
import 'widgets/ilustracao.dart';
import 'widgets/tileOpcao.dart';

/// Ecrã de esclarecimento de dúvidas sobre doação de sangue.
class EsclarecerScreen extends StatefulWidget {
  const EsclarecerScreen({super.key});

  @override
  State<EsclarecerScreen> createState() => _EsclarecerScreenState();
}

class _EsclarecerScreenState extends State<EsclarecerScreen> {
  int? _opcaoSeleccionada;

  static const _opcoes = [
    OpcaoAtendimento(
      Icons.phone_rounded,
      'Videochamada / Chamada',
      'Fale directamente com um profissional',
    ),
    OpcaoAtendimento(
      Icons.smart_toy_outlined,
      'Chat com IA',
      'Pergunte ao assistente de saúde',
    ),
    OpcaoAtendimento(
      Icons.chat_bubble_outline_rounded,
      'Mensagem para o Centro',
      'Envie uma dúvida ao centro de saúde',
    ),
  ];

  /// Inicia o canal de atendimento seleccionado.
  Future<void> _iniciarAtendimento() async {
    switch (_opcaoSeleccionada) {
      case 0:
        // Abre o WhatsApp com número de apoio
        const numero = '351932044469';
        final url = Uri.parse(
          'https://wa.me/$numero?text=Olá, gostaria de esclarecer uma dúvida sobre doação de sangue.',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
        break;

      case 1:
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatIAScreen()),
        );
        break;

      case 2:
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EscolherCentroChatScreen()),
        );
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
            const CabecalhoEsclarecer(),
            const SizedBox(height: 24),

            // Ilustração
            const IlustraoApoio(),
            const SizedBox(height: 28),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Como deseja ser atendido?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Lista de opções
            ...List.generate(
              _opcoes.length,
              (i) => TileOpcao(
                opcao: _opcoes[i],
                seleccionado: _opcaoSeleccionada == i,
                onSelected: () => setState(() => _opcaoSeleccionada = i),
              ),
            ),

            const Spacer(),

            // Botão iniciar
             BotaoIniciar(
              activo: _opcaoSeleccionada != null,
              onClick: _iniciarAtendimento,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}
