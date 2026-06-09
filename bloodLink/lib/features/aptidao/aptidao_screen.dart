// lib/features/aptidao/aptidao_screen.dart
//
// Ecrã informativo apresentado quando o utilizador tenta agendar
// uma doação sem ter avaliado a sua aptidão.
// Redireciona para o questionário de aptidão ao premir o botão.

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';

/// Ecrã de aviso de aptidão não avaliada.
class AptidaoScreen extends StatelessWidget {
  const AptidaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _IconeInformativo(),
              const SizedBox(height: 32),
              const _CartaoAviso(),
              const SizedBox(height: 40),
              _BotaoAvaliar(
                aoPremir: () => Navigator.pushNamed(
                    context, AppRoutesUser.questionario),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconeInformativo extends StatelessWidget {
  const _IconeInformativo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: Text(
          'i',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _CartaoAviso extends StatelessWidget {
  const _CartaoAviso();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Ainda não está apto para agendar uma doação.\nAvalie a sua aptidão antes de prosseguir.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15, height: 1.6, color: AppColors.textPrimary),
      ),
    );
  }
}

class _BotaoAvaliar extends StatelessWidget {
  final VoidCallback aoPremir;
  const _BotaoAvaliar({required this.aoPremir});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoPremir,
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
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.edit_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avaliar Aptidão',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  Text(
                    'Preencha o seguinte questionário',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
