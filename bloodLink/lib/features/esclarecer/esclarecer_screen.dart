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
import '../common/widgets/blood_drop.dart';
import '../chat_user/escolher_centro_chat_screen.dart';

/// Dados de uma opção de atendimento.
class _OpcaoAtendimento {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  const _OpcaoAtendimento(this.icone, this.titulo, this.subtitulo);
}

/// Ecrã de esclarecimento de dúvidas sobre doação de sangue.
class EsclarecerScreen extends StatefulWidget {
  const EsclarecerScreen({super.key});

  @override
  State<EsclarecerScreen> createState() => _EsclarecerScreenState();
}

class _EsclarecerScreenState extends State<EsclarecerScreen> {
  int _opcaoSeleccionada = -1;

  static const _opcoes = [
    _OpcaoAtendimento(
      Icons.phone_rounded,
      'Videochamada / Chamada',
      'Fale directamente com um profissional',
    ),
    _OpcaoAtendimento(
      Icons.smart_toy_outlined,
      'Chat com IA',
      'Pergunte ao assistente de saúde',
    ),
    _OpcaoAtendimento(
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
            'https://wa.me/$numero?text=Olá, gostaria de esclarecer uma dúvida sobre doação de sangue.');
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
          MaterialPageRoute(
              builder: (_) => const EscolherCentroChatScreen()),
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
            const _CabecalhoEsclarecer(),
            const SizedBox(height: 24),

            // Ilustração
            const _IlustraoApoio(),
            const SizedBox(height: 28),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Como deseja ser atendido?',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 14),

            // Lista de opções
            ...List.generate(
              _opcoes.length,
              (i) => _TileOpcao(
                opcao: _opcoes[i],
                seleccionado: _opcaoSeleccionada == i,
                aoSeleccionar: () =>
                    setState(() => _opcaoSeleccionada = i),
              ),
            ),

            const Spacer(),

            // Botão iniciar
            _BotaoIniciar(
              activo: _opcaoSeleccionada != -1,
              aoPremir: _iniciarAtendimento,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

/// Título e subtítulo do ecrã de esclarecimento.
class _CabecalhoEsclarecer extends StatelessWidget {
  const _CabecalhoEsclarecer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            BloodDrop(size: 22),
            SizedBox(width: 8),
            Text(
              'Esclarecer Dúvidas',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary),
            ),
          ]),
          const SizedBox(height: 4),
          const Text(
            'Fale com um profissional de saúde',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Ilustração decorativa da secção de apoio.
class _IlustraoApoio extends StatelessWidget {
  const _IlustraoApoio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.medical_information_outlined,
          size: 60,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Tile de opção de atendimento seleccionável.
class _TileOpcao extends StatelessWidget {
  final _OpcaoAtendimento opcao;
  final bool seleccionado;
  final VoidCallback aoSeleccionar;

  const _TileOpcao({
    required this.opcao,
    required this.seleccionado,
    required this.aoSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoSeleccionar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: seleccionado
              ? AppColors.primary.withOpacity(0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? AppColors.primary : AppColors.border,
            width: seleccionado ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          // Ícone
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: seleccionado
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              opcao.icone,
              color:
                  seleccionado ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opcao.titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: seleccionado
                        ? AppColors.primary
                        : AppColors.accent,
                  ),
                ),
                Text(
                  opcao.subtitulo,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // Check de selecção
          if (seleccionado)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 20),
        ]),
      ),
    );
  }
}

/// Botão de confirmação de início de atendimento.
class _BotaoIniciar extends StatelessWidget {
  final bool activo;
  final VoidCallback aoPremir;

  const _BotaoIniciar({required this.activo, required this.aoPremir});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: activo ? aoPremir : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.border,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Text(
          'Iniciar conversa',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white),
        ),
      ),
    );
  }
}
