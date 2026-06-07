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
        if (data['userId'] != null) {
          try {
            final userDoc = await _db.collection('users').doc(data['userId']).get();
            nomeUser = userDoc.data()?['nome'] ?? 'Utilizador';
          } catch (_) {}
        }
        final item = {...data, 'id': doc.id, 'nomeUser': nomeUser};
        if (data['estado'] == 'pendente') {
          pendentes.add(item);
        } else {
          confirmados.add(item);
        }
      }

      // Ordena por data+hora
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadPedidos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const BloodDrop(size: 22),
                      const SizedBox(width: 8),
                      const Text('Pedidos', style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ]),
                    const SizedBox(height: 20),

                    // ── Pendentes
                    Row(children: [
                      const Text('AGUARDAM RESPOSTA', style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.textMuted, letterSpacing: 0.5)),
                      const SizedBox(width: 8),
                      if (_pendentes.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${_pendentes.length}',
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                    ]),
                    const SizedBox(height: 10),

                    if (_pendentes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Sem pedidos pendentes.', style: TextStyle(color: AppColors.textMuted)),
                      )
                    else
                      ...  _pendentes.map((p) => _pedidoCard(p, isPendente: true)),

                    const SizedBox(height: 20),

                    // ── Confirmados
                    const Text('CONFIRMADOS', style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.textMuted, letterSpacing: 0.5)),
                    const SizedBox(height: 10),

                    if (_confirmados.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Sem agendamentos confirmados.', style: TextStyle(color: AppColors.textMuted)),
                      )
                    else
                      ..._confirmados.map((p) => _pedidoCard(p, isPendente: false)),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNavCentro(currentIndex: 2),
    );
  }

  Widget _pedidoCard(Map<String, dynamic> p, {required bool isPendente}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPendente ? AppColors.primary.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_outline, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['nomeUser'] ?? 'Utilizador',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
            Text('${_formatDataKey(p['dataKey'])} · ${p['hora']}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPendente
                  ? const Color(0xFFFFF3E0)
                  : const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPendente ? 'Pendente' : 'Confirmado',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: isPendente ? const Color(0xFFE65100) : const Color(0xFF22C55E),
              ),
            ),
          ),
        ]),

        // Botões aceitar/recusar apenas para pendentes
        if (isPendente) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _recusar(p['id']),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Recusar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _aceitar(p['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Aceitar', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}
