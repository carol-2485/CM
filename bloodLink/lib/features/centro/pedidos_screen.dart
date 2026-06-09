// lib/features/centro/pedidos_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../common/services/vagas_service.dart';
import '../common/widgets/blood_drop.dart';
import 'widgets/app_bottom_nav_centro.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});
  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final _db = FirebaseFirestore.instance;
  final _vagasService = VagasService();
  late String _centroId;
  List<Map<String, dynamic>> _pendentes = [];
  List<Map<String, dynamic>> _confirmados = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolverCentroId();
  }

  Future<void> _resolverCentroId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _db.collection('centros').doc(uid).get();
    if (doc.exists) {
      _centroId = uid;
    } else {
      final q = await _db.collection('centros').where('uid', isEqualTo: uid).limit(1).get();
      _centroId = q.docs.isNotEmpty ? q.docs.first.id : uid;
    }
    _loadPedidos();
  }

  Future<void> _loadPedidos() async {
    setState(() => _loading = true);
    try {
      final snap = await _db
          .collection('vagas')
          .where('centroId', isEqualTo: _centroId)
          .where('estado', whereIn: ['pendente', 'confirmado'])
          .get();

      final pendentes = <Map<String, dynamic>>[];
      final confirmados = <Map<String, dynamic>>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        String nomeUser = 'Utilizador';
        String? tipoSanguineo;
        if (data['userId'] != null) {
          try {
            final userDoc = await _db.collection('users').doc(data['userId']).get();
            nomeUser = userDoc.data()?['nome'] ?? 'Utilizador';
            tipoSanguineo = userDoc.data()?['tipoSanguineo'];
          } catch (_) {}
        }
        final item = {...data, 'id': doc.id, 'nomeUser': nomeUser, 'tipoSanguineo': tipoSanguineo};
        if (data['estado'] == 'pendente') {
          pendentes.add(item);
        } else {
          confirmados.add(item);
        }
      }

      for (final list in [pendentes, confirmados]) {
        list.sort((a, b) {
          final ka = '${a['dataKey']} ${a['hora']}';
          final kb = '${b['dataKey']} ${b['hora']}';
          return ka.compareTo(kb);
        });
      }

      if (mounted) setState(() { _pendentes = pendentes; _confirmados = confirmados; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _aceitar(String vagaId) async {
    await _vagasService.confirmarVaga(vagaId);
    _loadPedidos();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Agendamento confirmado! O utilizador foi notificado.'),
      backgroundColor: Color(0xFF22C55E),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _recusar(String vagaId) async {
    await _vagasService.recusarVaga(vagaId);
    _loadPedidos();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Pedido recusado. A vaga voltou a estar disponível.'),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _formatDataKey(String? key) {
    if (key == null) return '—';
    final p = key.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadPedidos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const BloodDrop(size: 22),
                      const SizedBox(width: 8),
                      const Text('Pedidos', style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      const Spacer(),
                      if (_pendentes.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${_pendentes.length} pendente${_pendentes.length > 1 ? 's' : ''}',
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Pendentes ──────────────────────────────────────────
                    if (_pendentes.isNotEmpty) ...[
                      _SeccaoLabel(
                        titulo: 'AGUARDAM RESPOSTA',
                        count: _pendentes.length,
                        cor: AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      ..._pendentes.map((p) => _PedidoCard(
                        pedido: p,
                        isPendente: true,
                        onAceitar: () => _aceitar(p['id']),
                        onRecusar: () => _recusar(p['id']),
                        formatDataKey: _formatDataKey,
                      )),
                      const SizedBox(height: 20),
                    ] else ...[
                      _SeccaoLabel(titulo: 'AGUARDAM RESPOSTA', count: 0, cor: AppColors.textMuted),
                      const SizedBox(height: 10),
                      _EmptyState(mensagem: 'Sem pedidos pendentes.'),
                      const SizedBox(height: 20),
                    ],

                    // ── Confirmados ────────────────────────────────────────
                    _SeccaoLabel(
                      titulo: 'CONFIRMADOS',
                      count: _confirmados.length,
                      cor: const Color(0xFF22C55E),
                    ),
                    const SizedBox(height: 10),

                    if (_confirmados.isEmpty)
                      _EmptyState(mensagem: 'Sem agendamentos confirmados.')
                    else
                      ..._confirmados.map((p) => _PedidoCard(
                        pedido: p,
                        isPendente: false,
                        onAceitar: () {},
                        onRecusar: () {},
                        formatDataKey: _formatDataKey,
                      )),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNavCentro(currentIndex: 2),
    );
  }
}

class _SeccaoLabel extends StatelessWidget {
  final String titulo;
  final int count;
  final Color cor;
  const _SeccaoLabel({required this.titulo, required this.count, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 14, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(titulo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: AppColors.textMuted, letterSpacing: 0.8)),
      if (count > 0) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Text('$count', style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w700)),
        ),
      ],
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  final String mensagem;
  const _EmptyState({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Icon(Icons.inbox_rounded, color: AppColors.textMuted.withValues(alpha: 0.5), size: 20),
        const SizedBox(width: 10),
        Text(mensagem, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ]),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final Map<String, dynamic> pedido;
  final bool isPendente;
  final VoidCallback onAceitar;
  final VoidCallback onRecusar;
  final String Function(String?) formatDataKey;

  const _PedidoCard({
    required this.pedido,
    required this.isPendente,
    required this.onAceitar,
    required this.onRecusar,
    required this.formatDataKey,
  });

  @override
  Widget build(BuildContext context) {
    final tipoSanguineo = pedido['tipoSanguineo'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPendente ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border,
          width: isPendente ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPendente
                ? AppColors.primary.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        // Cabeçalho colorido
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isPendente
                ? AppColors.primary.withValues(alpha: 0.05)
                : const Color(0xFF22C55E).withValues(alpha: 0.04),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            // Avatar com tipo sanguíneo
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isPendente
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : const Color(0xFF22C55E).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: tipoSanguineo != null
                  ? Center(
                      child: Text(tipoSanguineo,
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: isPendente ? AppColors.primary : const Color(0xFF22C55E),
                          )),
                    )
                  : Icon(Icons.person_outline,
                      color: isPendente ? AppColors.primary : const Color(0xFF22C55E),
                      size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pedido['nomeUser'] ?? 'Utilizador',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(formatDataKey(pedido['dataKey'] as String?),
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(width: 10),
                const Icon(Icons.access_time_rounded, size: 11, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(pedido['hora'] ?? '—',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ]),
            ])),
            // Badge estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isPendente
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFF22C55E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPendente ? 'Pendente' : 'Confirmado',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: isPendente ? const Color(0xFFE65100) : const Color(0xFF22C55E),
                ),
              ),
            ),
          ]),
        ),

        // Botões aceitar/recusar só para pendentes
        if (isPendente)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRecusar,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Recusar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAceitar,
                  icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  label: const Text('Aceitar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}
