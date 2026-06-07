// lib/features/home/home_screen.dart
//
// Ecrã inicial do utilizador após autenticação.
// Apresenta o estado de aptidão, acesso às funcionalidades principais
// e sincroniza automaticamente o histórico de doações ao iniciar.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../auth/services/auth_service.dart';
import '../common/services/chat_service.dart';
import '../common/services/doacoes_service.dart';
import '../common/widgets/action_tile.dart';
import '../common/widgets/app_bottom_nav.dart';
import '../common/widgets/profile_header.dart';
import '../common/widgets/section_label.dart';
import '../notificacoes/notificacoes_screen.dart';
import 'widgets/status_card.dart';

/// Ecrã inicial do utilizador autenticado.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Serviços ─────────────────────────────────────────────────────────────
  final _authService = AuthService();

  // ── Estado ───────────────────────────────────────────────────────────────
  Map<String, dynamic>? _dadosUtilizador;
  bool _aCarregar = true;

  @override
  void initState() {
    super.initState();
    _carregarUtilizador();
  }

  // ── Lógica de negócio ─────────────────────────────────────────────────────

  /// Sincroniza doações concluídas e carrega os dados do utilizador.
  Future<void> _carregarUtilizador() async {
    // Sincroniza agendamentos passados antes de carregar
    await DoacoesService.sincronizarDoacoesConcluidas();

    final dados = await _authService.getUserData();
    if (mounted) {
      setState(() {
        _dadosUtilizador = dados;
        _aCarregar = false;
      });
    }
  }

  /// Termina a sessão e redireciona para o ecrã de login.
  Future<void> _terminarSessao() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutesUser.login);
  }

  @override
  Widget build(BuildContext context) {
    // Extrai dados com valores por defeito seguros
    final primeiroNome =
        (_dadosUtilizador?['nome'] as String? ?? '').split(' ').first;
    final estaApto = _dadosUtilizador?['isEligible'] == true;
    final totalDoacoes = (_dadosUtilizador?['totalDoacoes'] ?? 0) as int;
    final fotoUrl = _dadosUtilizador?['fotoUrl'] as String?;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _aCarregar
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

                    // Cabeçalho com avatar, nome e sininho
                    ProfileHeader(
                      nome: primeiroNome,
                      subtitle: 'Pronto para salvar vidas hoje?',
                      onLogout: _terminarSessao,
                      fotoUrl: fotoUrl,
                      onNotificacoesTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificacoesScreen()),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card de estado de aptidão
                    StatusCard(isEligible: estaApto),
                    const SizedBox(height: 24),

                    // Secção de acções principais
                    const SectionLabel('O QUE QUER FAZER?'),
                    const SizedBox(height: 12),

                    // Acções do utilizador
                    _ListaAcoes(
                      totalDoacoes: totalDoacoes,
                      uid: uid,
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

// ── Widget de lista de acções ────────────────────────────────────────────────

/// Lista de ActionTiles com as funcionalidades disponíveis ao utilizador.
class _ListaAcoes extends StatelessWidget {
  final int totalDoacoes;
  final String uid;

  const _ListaAcoes({required this.totalDoacoes, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Doar Sangue
        ActionTile(
          icon: Icons.water_drop_rounded,
          iconBg: AppColors.primary,
          title: 'Doar Sangue',
          subtitle: 'Agendar próxima doação',
          onTap: () => Navigator.pushNamed(context, AppRoutesUser.centros),
        ),

        // Histórico de Doações
        ActionTile(
          icon: Icons.history_rounded,
          title: 'Histórico de Doações',
          subtitle: '$totalDoacoes doações registadas',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutesUser.historico),
        ),

        // Campanhas e Eventos (em breve)
        ActionTile(
          icon: Icons.campaign_rounded,
          title: 'Campanhas e Eventos',
          subtitle: 'Em breve disponível',
          onTap: () {}, // funcionalidade futura
        ),

        // Dúvidas e Consultas
        ActionTile(
          icon: Icons.help_outline_rounded,
          title: 'Dúvidas e Consultas',
          subtitle: 'FAQ e Apoio',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutesUser.esclarecer),
        ),

        // Mensagens — com badge de não lidas em tempo real
        StreamBuilder<int>(
          stream: ChatService().contagemNaoLidasUtilizador(uid),
          builder: (context, snapshot) {
            final naoLidas = snapshot.data ?? 0;
            return ActionTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Mensagens',
              subtitle: naoLidas > 0
                  ? '$naoLidas mensagens novas'
                  : 'Chat com centros de saúde',
              badge: naoLidas > 0 ? '$naoLidas' : null,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutesUser.chats),
            );
          },
        ),
      ],
    );
  }
}
