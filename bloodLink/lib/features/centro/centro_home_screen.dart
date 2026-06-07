// lib/features/centro/centro_home_screen.dart
//
// Ecrã inicial da sessão do centro de saúde.
// Apresenta o resumo do dia: consultas agendadas, pedidos pendentes
// e mensagens novas. Serve como ponto de entrada para todas as
// funcionalidades do centro.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../auth/services/auth_service.dart';
import '../common/services/chat_service.dart';
import '../common/widgets/action_tile.dart';
import '../common/widgets/highlight_card.dart';
import '../common/widgets/profile_header.dart';
import '../common/widgets/section_label.dart';
import '../chat_centro/chat_lista_screen.dart';
import 'widgets/app_bottom_nav_centro.dart';

/// Ecrã principal do centro de saúde após autenticação.
class CentroHomeScreen extends StatefulWidget {
  const CentroHomeScreen({super.key});

  @override
  State<CentroHomeScreen> createState() => _CentroHomeScreenState();
}

class _CentroHomeScreenState extends State<CentroHomeScreen> {
  // ── Serviços ──────────────────────────────────────────────────────────────
  final _servAutenticacao = AuthService();

  // ── Estado ────────────────────────────────────────────────────────────────
  Map<String, dynamic>? _dadosCentro;
  String? _idDocumentoCentro;
  int _consultasHoje = 0;
  int _pedidosPendentes = 0;
  bool _aCarregar = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // ── Lógica de negócio ─────────────────────────────────────────────────────

  /// Resolve o documento do centro e carrega os contadores do dia.
  Future<void> _carregarDados() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Resolve o documento do centro (pode ter ID diferente do UID)
    DocumentSnapshot docCentro = await FirebaseFirestore.instance
        .collection('centros')
        .doc(uid)
        .get();

    if (!docCentro.exists) {
      final q = await FirebaseFirestore.instance
          .collection('centros')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) docCentro = q.docs.first;
    }

    final idCentro = docCentro.id;

    // Chave do dia de hoje
    final hoje = DateTime.now();
    final chaveHoje =
        '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

    // Consultas confirmadas para hoje
    final snapConsultas = await FirebaseFirestore.instance
        .collection('vagas')
        .where('centroId', isEqualTo: idCentro)
        .where('dataKey', isEqualTo: chaveHoje)
        .where('estado', isEqualTo: 'confirmado')
        .get();

    // Pedidos a aguardar resposta
    final snapPendentes = await FirebaseFirestore.instance
        .collection('vagas')
        .where('centroId', isEqualTo: idCentro)
        .where('estado', isEqualTo: 'pendente')
        .get();

    if (mounted) {
      setState(() {
        _dadosCentro = docCentro.data() as Map<String, dynamic>?;
        _idDocumentoCentro = idCentro;
        _consultasHoje = snapConsultas.docs.length;
        _pedidosPendentes = snapPendentes.docs.length;
        _aCarregar = false;
      });
    }
  }

  /// Termina a sessão do centro de saúde.
  Future<void> _terminarSessao() async {
    await _servAutenticacao.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutesUser.login);
  }

  // ── Interface ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final nomeCentro = _dadosCentro?['nome'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _aCarregar
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Cabeçalho sem sininho (centro usa separador de pedidos)
                    ProfileHeader(
                      nome: nomeCentro,
                      subtitle: 'Bom dia! Aqui está o seu resumo.',
                      avatarIcon: Icons.local_hospital,
                      onLogout: _terminarSessao,
                      mostrarNotificacoes: false,
                    ),
                    const SizedBox(height: 24),

                    // Destaque: consultas agendadas para hoje
                    HighlightCard(
                      icon: Icons.today,
                      title: 'Consultas de Hoje',
                      subtitle: '$_consultasHoje consultas agendadas para hoje',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutesCentro.pedidos),
                    ),
                    const SizedBox(height: 24),

                    // Secção de atalhos
                    const SectionLabel('O QUE QUER FAZER?'),
                    const SizedBox(height: 12),

                    // Atalho: Gerir Vagas
                    ActionTile(
                      icon: Icons.event_available,
                      iconBg: AppColors.primary,
                      title: 'Gerir Vagas',
                      subtitle: 'Criar e editar slots disponíveis',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutesCentro.gerirVagas),
                    ),

                    // Atalho: Pedidos Pendentes (com badge)
                    ActionTile(
                      icon: Icons.pending_actions,
                      title: 'Pedidos Pendentes',
                      subtitle: _pedidosPendentes > 0
                          ? '$_pedidosPendentes a aguardar resposta'
                          : 'Sem pedidos pendentes',
                      badge:
                          _pedidosPendentes > 0 ? '$_pedidosPendentes' : null,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutesCentro.pedidos),
                    ),

                    // Atalho: Mensagens (com badge de não lidas em tempo real)
                    if (_idDocumentoCentro != null)
                      _AtalhoMensagensCentro(
                          idCentro: _idDocumentoCentro!),

                    // Atalho: Consultas Confirmadas
                    ActionTile(
                      icon: Icons.check_circle_outline,
                      title: 'Consultas Confirmadas',
                      subtitle: 'Ver próximas consultas',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutesCentro.pedidos),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNavCentro(currentIndex: 0),
    );
  }
}

// ── Widgets internos ─────────────────────────────────────────────────────────

/// Atalho para o chat com os doadores.
/// Usa [StreamBuilder] para apresentar o número de mensagens não lidas
/// em tempo real.
class _AtalhoMensagensCentro extends StatelessWidget {
  final String idCentro;
  const _AtalhoMensagensCentro({required this.idCentro});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: ChatService().unreadCountForCentro(idCentro),
      builder: (context, snap) {
        final naoLidas = snap.data ?? 0;
        return ActionTile(
          icon: Icons.chat_bubble_outline,
          title: 'Mensagens',
          subtitle:
              naoLidas > 0 ? '$naoLidas mensagens novas' : 'Chat com doadores',
          badge: naoLidas > 0 ? '$naoLidas' : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ChatListaCentroScreen()),
          ),
        );
      },
    );
  }
}
