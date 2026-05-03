// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../services/auth_service.dart';
import '../widgets/app_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await _auth.getUserData();
    if (mounted) setState(() { _userData = data; _loading = false; });
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final nome = (_userData?['nome'] as String? ?? '').split(' ').first;
    final isEligible = _userData?['isEligible'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.border,
                          child: const Icon(Icons.person, color: AppColors.textMuted, size: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                  children: [
                                    const TextSpan(text: 'Olá, ', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w500)),
                                    TextSpan(text: '$nome!', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                              const Text('Pronto para salvar vidas hoje?',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
                          onPressed: _logout,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Card de aptidão / avaliar
                    _buildStatusCard(isEligible),

                    const SizedBox(height: 24),

                    const Text('O que quer fazer?',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppColors.textMuted, letterSpacing: 0.5)),

                    const SizedBox(height: 12),

                    // Acções principais
                    _buildActionTile(
                      icon: Icons.water_drop_rounded,
                      iconBg: AppColors.primary,
                      title: 'Doar Sangue',
                      subtitle: 'Agendar próxima doação',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.centros),
                      hasArrow: true,
                    ),
                    _buildActionTile(
                      icon: Icons.history_rounded,
                      iconBg: AppColors.border,
                      title: 'Histórico de Doações',
                      subtitle: '${_userData?['totalDoacoes'] ?? 0} doações registadas',
                      onTap: () {},
                      hasArrow: true,
                    ),
                    _buildActionTile(
                      icon: Icons.campaign_rounded,
                      iconBg: AppColors.border,
                      title: 'Campanhas e Eventos',
                      subtitle: 'Em breve disponível',
                      onTap: () {},
                      hasArrow: true,
                    ),
                    _buildActionTile(
                      icon: Icons.help_outline_rounded,
                      iconBg: AppColors.border,
                      title: 'Dúvidas e Consultas',
                      subtitle: 'FAQ e Apoio',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.esclarecer),
                      hasArrow: true,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildStatusCard(bool isEligible) {
    if (isEligible) {
      return Container(
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
              child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('O SEU ESTADO', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600)),
                  Text('Apto para Doar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Válido', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.aptidao),
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
                  Text('Avaliar Aptidão', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('Preencha o seguinte questionário', style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool hasArrow = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconBg == AppColors.border ? AppColors.textMuted : iconBg, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (hasArrow) const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
