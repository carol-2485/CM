// lib/screens/aptidao_screen.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../widgets/app_bottom_nav.dart';

class AptidaoScreen extends StatelessWidget {
  const AptidaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone "i"
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text('i',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontStyle: FontStyle.italic)),
                ),
              ),

              const SizedBox(height: 32),

              // Card de aviso
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Ainda não está apto para agendar uma doação.\nAvalie a sua aptidão antes de prosseguir',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.6, color: AppColors.textPrimary),
                ),
              ),

              const SizedBox(height: 40),

              // Botão avaliar aptidão
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutesUser.questionario),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Avaliar Aptidão',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text('Preencha o seguinte questionário',
                                style: TextStyle(fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Sem navbar aqui — este ecrã é acedido a partir da Home
    );
  }
}
