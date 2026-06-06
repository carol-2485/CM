import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../auth/services/auth_service.dart';
import '../common/widgets/action_tile.dart';
import '../common/widgets/app_bottom_nav.dart';
import '../common/widgets/profile_header.dart';
import '../common/widgets/section_label.dart';
import 'widgets/status_card.dart';

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
    if (mounted) {
      setState(() {
        _userData = data;
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutesUser.login);
  }

  @override
  Widget build(BuildContext context) {
    final nome = (_userData?['nome'] as String? ?? '').split(' ').first;
    final isEligible = _userData?['isEligible'] == true;
    final totalDoacoes = _userData?['totalDoacoes'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    ProfileHeader(
                      nome: nome,
                      subtitle: 'Pronto para salvar vidas hoje?',
                      onLogout: _logout,
                    ),
                    const SizedBox(height: 24),
                    StatusCard(isEligible: isEligible),
                    const SizedBox(height: 24),
                    const SectionLabel('O QUE QUER FAZER?'),
                    const SizedBox(height: 12),
                    ActionTile(
                      icon: Icons.water_drop_rounded,
                      iconBg: AppColors.primary,
                      title: 'Doar Sangue',
                      subtitle: 'Agendar próxima doação',
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutesUser.centros,
                      ),
                    ),
                    ActionTile(
                      icon: Icons.history_rounded,
                      title: 'Histórico de Doações',
                      subtitle: '$totalDoacoes doações registadas',
                      onTap: () {},
                    ),
                    ActionTile(
                      icon: Icons.campaign_rounded,
                      title: 'Campanhas e Eventos',
                      subtitle: 'Em breve disponível',
                      onTap: () {},
                    ),
                    ActionTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Dúvidas e Consultas',
                      subtitle: 'FAQ e Apoio',
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutesUser.esclarecer,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}