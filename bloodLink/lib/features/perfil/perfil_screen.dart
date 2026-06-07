// lib/features/perfil/perfil_screen.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../auth/services/auth_service.dart';
import '../common/widgets/app_bottom_nav.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
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
    Navigator.pushReplacementNamed(context, AppRoutesUser.login);
  }

  Widget _infoRow(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
      const Spacer(),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final nome = _userData?['nome'] ?? '—';
    final email = _userData?['email'] ?? '—';
    final idade = _userData?['idade'] ?? '—';
    final sangue = _userData?['tipoSanguineo'] ?? '—';
    final historico = _userData?['historicoDencas'] ?? '—';
    final dataDoacao = _userData?['dataUltimaDoacao'] ?? '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              child: Column(children: [
                // Avatar + nome
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person_rounded, size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(nome, style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.accent)),
                Text(email, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 24),

                // Informações
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(children: [
                    _infoRow('Idade', '$idade anos'),
                    _infoRow('Tipo Sanguíneo', sangue),
                    _infoRow('Histórico de doenças', historico),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(children: [
                        const Text('Última doação', style: TextStyle(
                            fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text(dataDoacao.toString().isEmpty ? '—' : dataDoacao,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // Botão terminar sessão
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: OutlinedButton(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Terminar sessão',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }
}
