// lib/screens/esclarecer_screen.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/app_bottom_nav.dart';

enum TipoAtendimento { videochamada, chatAoVivo, perguntaEscrita }

class EsclarecerScreen extends StatefulWidget {
  const EsclarecerScreen({super.key});

  @override
  State<EsclarecerScreen> createState() => _EsclarecerScreenState();
}

class _EsclarecerScreenState extends State<EsclarecerScreen> {
  TipoAtendimento _selected = TipoAtendimento.videochamada;

  void _iniciarConsulta() {
    // TODO: navegar para o fluxo de consulta consoante _selected
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('A iniciar consulta: ${_labelFor(_selected)}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  String _labelFor(TipoAtendimento tipo) {
    switch (tipo) {
      case TipoAtendimento.videochamada:
        return 'Videochamada';
      case TipoAtendimento.chatAoVivo:
        return 'Chat ao vivo';
      case TipoAtendimento.perguntaEscrita:
        return 'Deixar pergunta escrita';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Back arrow
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: AppColors.accent),
              ),

              const SizedBox(height: 16),

              // Título + subtítulo
              const Text(
                'Esclarecer Dúvidas',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                  fontFamily: 'Poppins',
                ),
              ),
              const Text(
                'Fale com um profissional de saúde',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // Imagem do médico
              _buildDoctorCard(),

              const SizedBox(height: 20),

              // Secção de escolha
              const Text(
                'Como deseja ser atendido?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),

              const SizedBox(height: 12),

              _buildRadioOption(TipoAtendimento.videochamada, 'Videochamada'),
              _buildRadioOption(TipoAtendimento.chatAoVivo, 'Chat ao vivo'),
              _buildRadioOption(TipoAtendimento.perguntaEscrita, 'Deixar pergunta escrita'),

              const SizedBox(height: 16),

              // Nota de disponibilidade
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Disponível das 8h às 18h.\nA resposta pode demorar alguns minutos',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botão principal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _iniciarConsulta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildDoctorCard() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF5F0E8), Color(0xFFE8DDD0)],
              ),
            ),
          ),
          // Ícone do médico (placeholder enquanto não há imagem)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.border,
                  child: Icon(
                    Icons.person,
                    size: 54,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Profissional de Saúde',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    // Quando tivermos a imagem real, substitui-mos o widget acima por:
    // Image.asset('assets/images/doctor.png' , fit: BoxFit.cover)
  }

  Widget _buildRadioOption(TipoAtendimento tipo, String label) {
    final isSelected = _selected == tipo;
    return GestureDetector(
      onTap: () => setState(() => _selected = tipo),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 