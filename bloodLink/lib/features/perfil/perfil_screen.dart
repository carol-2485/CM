// lib/features/perfil/perfil_screen.dart
//
// Ecrã de gestão de perfil do utilizador doador.
// Apresenta informações de saúde e dados pessoais organizados
// em cartões separados, com opção de terminar sessão.

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../auth/services/auth_service.dart';
import '../common/widgets/app_bottom_nav.dart';
import 'widgets/cabecalho_perfil.dart';
import 'widgets/cartao_info_perfil.dart';
import 'widgets/botao_terminar_sessao.dart';

/// Ecrã de perfil do utilizador autenticado.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // ── Serviços ──────────────────────────────────────────────────────────────
  final _servAutenticacao = AuthService();

  // ── Estado ────────────────────────────────────────────────────────────────
  Map<String, dynamic>? _dadosUtilizador;
  bool _aCarregar = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  // ── Lógica de negócio ─────────────────────────────────────────────────────

  /// Carrega os dados do perfil do utilizador autenticado.
  Future<void> _carregarPerfil() async {
    final dados = await _servAutenticacao.getUserData();
    if (mounted) {
      setState(() {
        _dadosUtilizador = dados;
        _aCarregar = false;
      });
    }
  }

  /// Termina a sessão e redireciona para o ecrã de login.
  Future<void> _terminarSessao() async {
    await _servAutenticacao.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutesUser.login);
  }

  @override
  Widget build(BuildContext context) {
    if (_aCarregar) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // Extrai valores com fallback seguro
    final nome = _dadosUtilizador?['nome'] as String? ?? '—';
    final email = _dadosUtilizador?['email'] as String? ?? '—';
    final idade = _dadosUtilizador?['idade']?.toString() ?? '—';
    final sangue = _dadosUtilizador?['tipoSanguineo'] as String? ?? '—';
    final historico = _dadosUtilizador?['historicoDencas'] as String? ?? '—';
    final dataDoacao = _dadosUtilizador?['dataUltimaDoacao']?.toString();
    final totalDoacoes = (_dadosUtilizador?['totalDoacoes'] ?? 0) as int;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Cabeçalho com avatar, nome e estatísticas
          SliverToBoxAdapter(
            child: CabecalhoPerfil(
              nome: nome,
              email: email,
              totalDoacoes: totalDoacoes,
              tipoSanguineo: sangue,
              idade: idade,
              onVoltar: () => Navigator.pop(context),
            ),
          ),

          // Conteúdo em cartões
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Secção de saúde
                const _RotuloSecao(
                  titulo: 'Informações de Saúde',
                  icone: Icons.health_and_safety_outlined,
                ),
                const SizedBox(height: 10),
                CartaoInfoPerfil(linhas: [
                  LinhaInfo(
                    rotulo: 'Tipo Sanguíneo',
                    valor: sangue,
                    icone: Icons.water_drop_rounded,
                    corIcone: AppColors.primary,
                  ),
                  LinhaInfo(
                    rotulo: 'Histórico de doenças',
                    valor: historico,
                    icone: Icons.medical_information_outlined,
                    corIcone: const Color(0xFF6366F1),
                  ),
                  LinhaInfo(
                    rotulo: 'Última doação',
                    valor: (dataDoacao == null || dataDoacao.isEmpty)
                        ? '—'
                        : dataDoacao,
                    icone: Icons.history_rounded,
                    corIcone: const Color(0xFFF59E0B),
                  ),
                ]),
                const SizedBox(height: 20),

                // Secção de dados pessoais
                const _RotuloSecao(
                  titulo: 'Dados Pessoais',
                  icone: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 10),
                CartaoInfoPerfil(linhas: [
                  LinhaInfo(
                    rotulo: 'Nome completo',
                    valor: nome,
                    icone: Icons.badge_outlined,
                    corIcone: const Color(0xFF0EA5E9),
                  ),
                  LinhaInfo(
                    rotulo: 'Endereço de email',
                    valor: email,
                    icone: Icons.email_outlined,
                    corIcone: const Color(0xFF8B5CF6),
                  ),
                  LinhaInfo(
                    rotulo: 'Idade',
                    valor: '$idade anos',
                    icone: Icons.cake_outlined,
                    corIcone: const Color(0xFFEC4899),
                  ),
                ]),
                const SizedBox(height: 28),

                // Botão de terminar sessão
                BotaoTerminarSessao(onTap: _terminarSessao),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

/// Rótulo de secção com ícone e título.
class _RotuloSecao extends StatelessWidget {
  final String titulo;
  final IconData icone;

  const _RotuloSecao({required this.titulo, required this.icone});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icone, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(
        titulo,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.accent,
        ),
      ),
    ]);
  }
}
