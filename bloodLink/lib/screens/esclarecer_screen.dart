// lib/screens/esclarecer_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../widgets/app_bottom_nav.dart';

enum TipoAtendimento { videochamada, chatAoVivo, perguntaEscrita }

// Número do profissional de saúde (formato internacional sem '+')
const String _whatsappNumero = '351900000000'; // ← substitui pelo número real

class EsclarecerScreen extends StatefulWidget {
  const EsclarecerScreen({super.key});

  @override
  State<EsclarecerScreen> createState() => _EsclarecerScreenState();
}

class _EsclarecerScreenState extends State<EsclarecerScreen> {
  TipoAtendimento _selected = TipoAtendimento.videochamada;

  Future<void> _iniciarConsulta() async {
    switch (_selected) {
      case TipoAtendimento.videochamada:
        await _abrirWhatsApp(
          'Olá! Gostaria de agendar uma videochamada com um profissional de saúde.',
        );
        break;
      case TipoAtendimento.chatAoVivo:
        await _abrirWhatsApp(
          'Olá! Gostaria de iniciar um chat ao vivo com um profissional de saúde.',
        );
        break;
      case TipoAtendimento.perguntaEscrita:
        // TODO: navegar para ecrã de pergunta escrita
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidade em breve disponível'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
        break;
    }
  }

  Future<void> _abrirWhatsApp(String mensagem) async {
    final uri = Uri.parse(
      'https://wa.me/$_whatsappNumero?text=${Uri.encodeComponent(mensagem)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o WhatsApp'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
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

            // ── Header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seta de volta
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Título bold — centrado
                  const SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Esclarecer Dúvidas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                        fontFamily: 'Poppins',
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Subtítulo vermelho — centrado
                  const SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Fale com um profissional de saúde',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Imagem do médico — largura total, sem card/borda ──
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 210,
              child: Image.asset(
                'assets/images/doctor.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                // Placeholder enquanto não tens a imagem:
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    Icons.person,
                    size: 120,
                    color: AppColors.border,
                  ),
                ),
              ),
            ),

            // ── Resto do conteúdo ─────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Pergunta
                    const Text(
                      'Como deseja ser atendido?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        fontFamily: null,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Opções — simples, sem container/borda à volta
                    _buildRadioOption(
                        TipoAtendimento.videochamada, 'Videochamada'),
                    _buildRadioOption(
                        TipoAtendimento.chatAoVivo, 'Chat ao vivo'),
                    _buildRadioOption(
                        TipoAtendimento.perguntaEscrita, 'Deixar pergunta escrita'),

                    const SizedBox(height: 10),

                    // Nota de disponibilidade — itálico, fonte do sistema
                    const Text(
                      'Disponível das 8h às 18h.\nA resposta pode demorar alguns minutos',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textMuted,
                        fontFamily: null,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Botão "Iniciar Consulta"
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _iniciarConsulta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Iniciar Consulta',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildRadioOption(TipoAtendimento tipo, String label) {
    final isSelected = _selected == tipo;
    return GestureDetector(
      onTap: () => setState(() => _selected = tipo),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Círculo exterior sempre visível
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  width: isSelected ? 6 : 1.5,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                fontFamily: null, // fonte do sistema, igual ao Figma
              ),
            ),
          ],
        ),
      ),
    );
  }
}