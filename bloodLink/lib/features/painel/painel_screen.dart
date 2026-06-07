// lib/features/painel/painel_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../auth/services/auth_service.dart';
import '../common/widgets/app_bottom_nav.dart';

class PainelScreen extends StatefulWidget {
  const PainelScreen({super.key});
  @override
  State<PainelScreen> createState() => _PainelScreenState();
}

class _PainelScreenState extends State<PainelScreen> {
  final _auth = AuthService();
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _proximoAgendamento;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Dados do utilizador
    final userData = await _auth.getUserData();

    // Próximo agendamento — busca vagas pendentes ou confirmadas
    Map<String, dynamic>? proximo;
    try {
      final hoje = DateTime.now();
      final hojeKey = '${hoje.year}-${hoje.month.toString().padLeft(2,'0')}-${hoje.day.toString().padLeft(2,'0')}';

      final snap = await FirebaseFirestore.instance
          .collection('vagas')
          .where('userId', isEqualTo: uid)
          .where('estado', whereIn: ['pendente', 'confirmado'])
          .get();

      // Filtra vagas futuras e ordena
      final futuras = snap.docs
          .where((d) => (d['dataKey'] as String? ?? '').compareTo(hojeKey) >= 0)
          .toList();
      futuras.sort((a, b) {
        final ka = '${a['dataKey']} ${a['hora']}';
        final kb = '${b['dataKey']} ${b['hora']}';
        return ka.compareTo(kb);
      });

      if (futuras.isNotEmpty) {
        final d = futuras.first.data();
        // Vai buscar o nome do centro
        String centroNome = 'Centro de Saúde';
        try {
          final centroDoc = await FirebaseFirestore.instance
              .collection('centros').doc(d['centroId']).get();
          if (centroDoc.exists) {
            centroNome = centroDoc.data()?['nome'] ?? centroNome;
          }
        } catch (_) {}

        proximo = {
          'centroNome': centroNome,
          'dataKey': d['dataKey'],
          'hora': d['hora'],
          'estado': d['estado'], // 'pendente' ou 'confirmado'
        };
      }
    } catch (e) {
      debugPrint('Erro ao carregar agendamento: $e');
    }

    if (mounted) {
      setState(() {
        _userData = userData;
        _proximoAgendamento = proximo;
        _loading = false;
      });
    }
  }

  String _formatDataKey(String dataKey) {
    final p = dataKey.split('-');
    if (p.length != 3) return dataKey;
    return '${p[2]}/${p[1]}/${p[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final nome = _userData?['nome'] as String? ?? 'Utilizador';
    final isEligible = _userData?['isEligible'] == true;
    final totalDoacoes = (_userData?['totalDoacoes'] ?? 0) as int;
    final pessoasAjudadas = totalDoacoes * 3;
    final sangueDoado = (totalDoacoes * 0.45).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                // ── Header vermelho
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                            ),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('PAINEL DO DOADOR', style: TextStyle(
                                    fontSize: 10, color: Colors.white70,
                                    fontWeight: FontWeight.w700, letterSpacing: 1)),
                                const SizedBox(height: 4),
                                Text(nome, style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                                const Text('Doador BloodLink', style: TextStyle(fontSize: 12, color: Colors.white70)),
                              ])),
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                              ),
                            ]),
                            const SizedBox(height: 14),
                            Row(children: [
                              _metrica('$totalDoacoes', 'Doações'),
                              const SizedBox(width: 10),
                              _metrica('$pessoasAjudadas', 'Pessoas\nsalvas'),
                              const SizedBox(width: 10),
                              _metrica('${sangueDoado}L', 'Sangue\ndoado'),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      // ── Estado actual
                      _infoCard(
                        iconBg: isEligible
                            ? const Color(0xFF22C55E).withOpacity(0.15)
                            : AppColors.error.withOpacity(0.1),
                        icon: isEligible ? Icons.check_circle_outline : Icons.pending_actions_rounded,
                        iconColor: isEligible ? const Color(0xFF22C55E) : AppColors.error,
                        label: 'ESTADO ATUAL',
                        child: isEligible
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
                                ),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.circle, size: 6, color: Color(0xFF22C55E)),
                                  SizedBox(width: 4),
                                  Text('Apto para doar', style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF22C55E))),
                                ]),
                              )
                            : TextButton(
                                onPressed: () => Navigator.pushNamed(context, AppRoutesUser.questionario),
                                child: const Text('Avaliar aptidão',
                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                              ),
                      ),
                      const SizedBox(height: 10),

                      // ── Próximo agendamento
                      _infoCard(
                        iconBg: AppColors.primary.withOpacity(0.1),
                        icon: Icons.calendar_month_outlined,
                        iconColor: AppColors.primary,
                        label: 'PRÓXIMO AGENDAMENTO',
                        trailing: _proximoAgendamento == null
                            ? TextButton(
                                onPressed: () => Navigator.pushNamed(context, AppRoutesUser.centros),
                                child: const Text('Agendar',
                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                              )
                            : null,
                        child: _proximoAgendamento != null
                            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(_proximoAgendamento!['centroNome'] as String,
                                    style: const TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Text(_proximoAgendamento!['hora'] as String,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                  const SizedBox(width: 10),
                                  Text(_formatDataKey(_proximoAgendamento!['dataKey'] as String),
                                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _proximoAgendamento!['estado'] == 'confirmado'
                                          ? const Color(0xFF22C55E).withOpacity(0.12)
                                          : const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _proximoAgendamento!['estado'] == 'confirmado' ? 'Confirmado' : 'Pendente',
                                      style: TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.w600,
                                        color: _proximoAgendamento!['estado'] == 'confirmado'
                                            ? const Color(0xFF22C55E)
                                            : const Color(0xFFE65100),
                                      ),
                                    ),
                                  ),
                                ]),
                              ])
                            : const Text('Sem agendamentos futuros',
                                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ),
                      const SizedBox(height: 10),

                      // ── Última doação
                      _infoCard(
                        iconBg: const Color(0xFFFFEDED),
                        icon: Icons.history_rounded,
                        iconColor: AppColors.primary,
                        label: 'ÚLTIMA DOAÇÃO',
                        child: Text(
                          _userData?['dataUltimaDoacao'] != null &&
                                  (_userData!['dataUltimaDoacao'] as String).isNotEmpty
                              ? _userData!['dataUltimaDoacao'] as String
                              : 'Ainda não realizou doações',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── O meu impacto
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('O MEU IMPACTO', style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: AppColors.textMuted, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: _impactoMini('$totalDoacoes', 'Total de doações')),
                            const SizedBox(width: 10),
                            Expanded(child: _impactoMini('$pessoasAjudadas', 'Pessoas ajudadas')),
                          ]),
                          const SizedBox(height: 10),
                          // Barra de progresso para próxima doação (56 dias entre doações)
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Progresso para próxima doação',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            Text('${totalDoacoes > 0 ? "Em breve" : "—"}',
                                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: totalDoacoes > 0 ? 0.7 : 0.0,
                              backgroundColor: const Color(0xFFEDE0D4),
                              color: AppColors.primary,
                              minHeight: 6,
                            ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 12),

                      // Botão agendar (se elegível)
                      if (isEligible)
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, AppRoutesUser.centros),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Agendar Nova Doação', style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                            ]),
                          ),
                        ),
                    ]),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _metrica(String valor, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.white70, height: 1.2)),
      ]),
    ),
  );

  Widget _infoCard({
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: AppColors.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          child,
        ])),
        if (trailing != null) trailing,
      ]),
    );
  }

  Widget _impactoMini(String valor, String label) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
    ]),
  );
}
