import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/centro/app_bottom_nav_centro.dart';
import '../../constants/app_colors.dart';


class CentroHomeScreen extends StatelessWidget {
  const CentroHomeScreen({super.key});

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
              _buildHeader(),
              const SizedBox(height: 24),
              _buildConsultasHojeCard(),
              const SizedBox(height: 24),
              const Text(
                'O QUE QUER FAZER?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                icon: Icons.event_available,
                title: 'Gerir Vagas',
                subtitle: 'Criar e editar slots disponíveis',
                onTap: () {},
              ),
              _buildOptionCard(
                icon: Icons.pending_actions,
                title: 'Pedidos Pendentes',
                subtitle: '3 pedidos a aguardar resposta',
                badge: '3',
                onTap: () {},
              ),
              _buildOptionCard(
                icon: Icons.check_circle_outline,
                title: 'Consultas Confirmadas',
                subtitle: 'Ver próximas consultas',
                onTap: () {},
              ),
              _buildOptionCard(
                icon: Icons.history,
                title: 'Histórico',
                subtitle: 'Consultas anteriores',
                onTap: () {},
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavCentro(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.surface,
          child: Icon(Icons.local_hospital, color: AppColors.primary, size: 30),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(text: 'Olá, '),
                  TextSpan(
                    text: 'Centro de Setúbal!',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Bom dia! Aqui está o seu resumo.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConsultasHojeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Consultas de Hoje',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '5 consultas agendadas para hoje',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.arrow_forward, color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}