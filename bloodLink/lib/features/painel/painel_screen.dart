// lib/features/painel/painel_screen.dart
//
// Ecrã do painel do doador. Centraliza as informações principais:
// - Estatísticas de doações (total, sangue doado, vidas salvas)
// - Estado de aptidão actual
// - Próximo agendamento
// - Última doação realizada
// - Botão de novo agendamento

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../auth/services/auth_service.dart';
import '../common/services/doacoes_service.dart';
import '../common/widgets/app_bottom_nav.dart';
import '../notificacoes/notificacoes_screen.dart';
import 'widgets/botao_agendar.dart';
import 'widgets/card_agendamento.dart';
import 'widgets/card_estado.dart';
import 'widgets/card_ultima_doacao.dart';
import 'widgets/header_painel.dart';

/// Ecrã do painel do doador de sangue.
class PainelScreen extends StatefulWidget {
  const PainelScreen({super.key});

  @override
  State<PainelScreen> createState() => _PainelScreenState();
}

class _PainelScreenState extends State<PainelScreen> {
  // ── Serviços ─────────────────────────────────────────────────────────────
  final _authService = AuthService();

  // ── Estado ───────────────────────────────────────────────────────────────
  Map<String, dynamic>? _dadosUtilizador;
  Map<String, dynamic>? _proximoAgendamento;
  bool _aCarregar = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // ── Lógica de negócio ─────────────────────────────────────────────────────

  /// Carrega dados do utilizador e sincroniza doações concluídas.
  Future<void> _carregarDados() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Sincroniza primeiro para ter totalDoacoes actualizado
    await DoacoesService.sincronizarDoacoesConcluidas();

    final dadosUtilizador = await _authService.getUserData();
    final proximoAgendamento = await _carregarProximoAgendamento(uid);

    if (mounted) {
      setState(() {
        _dadosUtilizador = dadosUtilizador;
        _proximoAgendamento = proximoAgendamento;
        _aCarregar = false;
      });
    }
  }

  /// Busca o próximo agendamento confirmado ou pendente do utilizador.
  ///
  /// Filtra agendamentos a partir de hoje e ordena por data/hora crescente.
  Future<Map<String, dynamic>?> _carregarProximoAgendamento(String uid) async {
    try {
      final hoje = DateTime.now();
      final chaveHoje =
          '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

      final resultado = await FirebaseFirestore.instance
          .collection('vagas')
          .where('userId', isEqualTo: uid)
          .where('estado', whereIn: ['pendente', 'confirmado'])
          .get();

      // Filtra apenas futuras e ordena por data+hora
      final futuras = resultado.docs
          .where((d) =>
              (d['dataKey'] as String? ?? '').compareTo(chaveHoje) >= 0)
          .toList()
        ..sort((a, b) {
          final chaveA = '${a['dataKey']} ${a['hora']}';
          final chaveB = '${b['dataKey']} ${b['hora']}';
          return chaveA.compareTo(chaveB);
        });

      if (futuras.isEmpty) return null;

      final dados = futuras.first.data();
      final nomeCentro = await _obterNomeCentro(dados['centroId'] as String?);

      return {
        'centroNome': nomeCentro,
        'dataKey': dados['dataKey'],
        'hora': dados['hora'],
        'estado': dados['estado'],
      };
    } catch (erro) {
      debugPrint('Erro ao carregar próximo agendamento: $erro');
      return null;
    }
  }

  /// Busca o nome do centro pelo ID no Firestore.
  Future<String> _obterNomeCentro(String? centroId) async {
    if (centroId == null) return 'Centro de Saúde';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('centros')
          .doc(centroId)
          .get();
      return doc.data()?['nome'] as String? ?? 'Centro de Saúde';
    } catch (_) {
      return 'Centro de Saúde';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extrai dados do utilizador com valores por defeito
    final nomeCompleto =
        _dadosUtilizador?['nome'] as String? ?? 'Utilizador';
    final primeiroNome = nomeCompleto.split(' ').first;
    final estaApto = _dadosUtilizador?['isEligible'] == true;
    final totalDoacoes = (_dadosUtilizador?['totalDoacoes'] ?? 0) as int;
    final vidasSalvas = totalDoacoes * 3;
    final sangueDoado = totalDoacoes * 0.45;
    final fotoUrl = _dadosUtilizador?['fotoUrl'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _aCarregar
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : CustomScrollView(
              slivers: [
                // Cabeçalho com avatar e contadores
                SliverToBoxAdapter(
                  child: HeaderPainel(
                    nome: primeiroNome,
                    fotoUrl: fotoUrl,
                    totalDoacoes: totalDoacoes,
                    sangueDoado: sangueDoado,
                    pessoasSalvas: vidasSalvas,
                    onNotificacoesTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificacoesScreen()),
                    ),
                    onVoltar: () => Navigator.pop(context),
                  ),
                ),

                // Conteúdo principal
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Estado de aptidão
                      CardEstado(estaApto: estaApto),
                      const SizedBox(height: 10),

                      // Próximo agendamento
                      CardAgendamento(
                        proximoAgendamento: _proximoAgendamento,
                        aoAgendar: () => Navigator.pushNamed(
                            context, AppRoutesUser.centros),
                      ),
                      const SizedBox(height: 10),

                      // Última doação
                      CardUltimaDoacao(
                        dataUltimaDoacao:
                            _dadosUtilizador?['dataUltimaDoacao'],
                      ),
                      const SizedBox(height: 16),

                      // Botão de agendamento (apenas se apto)
                      if (estaApto)
                        BotaoAgendar(
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutesUser.centros),
                        ),
                    ]),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}
