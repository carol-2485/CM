// lib/features/centro/gerir_vagas_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../common/widgets/blood_drop.dart';
import 'widgets/app_bottom_nav_centro.dart';

class _Vaga {
  final String id;
  final String hora;
  String estado; // 'disponivel' | 'indisponivel' | 'ocupado'
  String? nomeUser;

  _Vaga({required this.id, required this.hora, required this.estado, this.nomeUser});
}

class GerirVagasScreen extends StatefulWidget {
  const GerirVagasScreen({super.key});
  @override
  State<GerirVagasScreen> createState() => _GerirVagasScreenState();
}

class _GerirVagasScreenState extends State<GerirVagasScreen> {
  final _db = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();
  List<_Vaga> _vagas = [];
  bool _loading = false;
  late String _centroId;

  static const _horariosDefault = [
    '09:00','09:30','10:00','10:30','11:00','11:30',
    '12:00','12:30','13:00','13:30','14:00','14:30',
    '15:00','15:30','16:00','16:30','17:00','17:30',
  ];

  @override
  void initState() {
    super.initState();
    _centroId = FirebaseAuth.instance.currentUser!.uid;
    _resolverCentroId();
  }

  Future<void> _resolverCentroId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('centros').doc(uid).get();
    if (doc.exists) {
      _centroId = uid;
    } else {
      final q = await FirebaseFirestore.instance
          .collection('centros').where('uid', isEqualTo: uid).limit(1).get();
      if (q.docs.isNotEmpty) _centroId = q.docs.first.id;
    }
    _loadVagas();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _loadVagas() async {
    setState(() => _loading = true);
    try {
      final key = _dateKey(_selectedDate);
      final snap = await _db
          .collection('vagas')
          .where('centroId', isEqualTo: _centroId)
          .where('dataKey', isEqualTo: key)
          .get();

      List<QueryDocumentSnapshot> docs;
      if (snap.docs.isEmpty) {
        await _gerarVagasPadrao(key);
        final snap2 = await _db
            .collection('vagas')
            .where('centroId', isEqualTo: _centroId)
            .where('dataKey', isEqualTo: key)
            .get();
        docs = snap2.docs;
      } else {
        docs = snap.docs;
      }

      // Buscar nomes dos utilizadores para vagas ocupadas/pendentes/confirmadas
      final vagas = <_Vaga>[];
      for (final d in docs) {
        String? nomeUser;
        final userId = d['userId'];
        if (userId != null && (d['estado'] == 'ocupado' || d['estado'] == 'confirmado' || d['estado'] == 'pendente')) {
          try {
            final userDoc = await _db.collection('users').doc(userId).get();
            nomeUser = userDoc.data()?['nome'];
          } catch (_) {}
        }
        vagas.add(_Vaga(id: d.id, hora: d['hora'], estado: d['estado'], nomeUser: nomeUser));
      }

      vagas.sort((a, b) => a.hora.compareTo(b.hora));
      if (mounted) setState(() { _vagas = vagas; _loading = false; });
    } catch (e) {
      debugPrint('Erro ao carregar vagas: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _gerarVagasPadrao(String dataKey) async {
    final batch = _db.batch();
    for (final hora in _horariosDefault) {
      final ref = _db.collection('vagas').doc();
      batch.set(ref, {'centroId': _centroId, 'dataKey': dataKey, 'hora': hora, 'estado': 'disponivel', 'userId': null});
    }
    await batch.commit();
  }

  Future<void> _toggleVaga(_Vaga vaga) async {
    if (vaga.estado == 'ocupado' || vaga.estado == 'confirmado' || vaga.estado == 'pendente') return;
    final novoEstado = vaga.estado == 'disponivel' ? 'indisponivel' : 'disponivel';
    await _db.collection('vagas').doc(vaga.id).update({'estado': novoEstado});
    setState(() => vaga.estado = novoEstado);
  }

  void _prevDay() {
    setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
    _loadVagas();
  }

  void _nextDay() {
    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
    _loadVagas();
  }

  String _formatDate(DateTime d) {
    const dias = ['domingo','segunda','terça','quarta','quinta','sexta','sábado'];
    const meses = ['jan.','fev.','mar.','abr.','mai.','jun.','jul.','ago.','set.','out.','nov.','dez.'];
    return '${dias[d.weekday % 7]}, ${d.day} de ${meses[d.month - 1]} ${d.year}';
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(children: [
              const BloodDrop(size: 22),
              const SizedBox(width: 8),
              const Text('Gerir Vagas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ]),
          ),

          // Navegador de dia
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.chevron_left, color: AppColors.accent), onPressed: _prevDay),
              Expanded(child: Text(_formatDate(_selectedDate),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent))),
              IconButton(icon: const Icon(Icons.chevron_right, color: AppColors.accent), onPressed: _nextDay),
            ]),
          ),
          const SizedBox(height: 10),

          // Legenda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _legend(const Color(0xFF22C55E), 'Disponível'),
              const SizedBox(width: 14),
              _legend(AppColors.textMuted.withOpacity(0.4), 'Indisponível'),
              const SizedBox(width: 14),
              _legend(AppColors.primary, 'Ocupado'),
            ]),
          ),
          const SizedBox(height: 8),

          // Lista
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    itemCount: _vagas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) => _VagaTile(
                      vaga: _vagas[i],
                      onToggle: () => _toggleVaga(_vagas[i]),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavCentro(currentIndex: 1),
    );
  }

  Widget _legend(Color color, String label) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
  ]);
}

class _VagaTile extends StatelessWidget {
  final _Vaga vaga;
  final VoidCallback onToggle;
  const _VagaTile({required this.vaga, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isOcupado = vaga.estado == 'ocupado' || vaga.estado == 'confirmado' || vaga.estado == 'pendente';
    final isDisponivel = vaga.estado == 'disponivel';
    final isIndisponivel = vaga.estado == 'indisponivel';

    Color borderColor;
    Color bgColor;
    Color horaColor;
    Widget trailing;

    if (isOcupado) {
      // Vaga com utilizador — exibe estilo do protótipo: fundo rosado, barra vermelha
      final estadoLabel = vaga.estado == 'confirmado'
          ? 'confirmado'
          : vaga.estado == 'pendente'
              ? 'pendente'
              : 'ocupado';
      borderColor = AppColors.primary.withOpacity(0.3);
      bgColor = AppColors.primary.withOpacity(0.06);
      horaColor = AppColors.textMuted;
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: vaga.estado == 'confirmado'
              ? const Color(0xFF22C55E).withOpacity(0.12)
              : const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          estadoLabel,
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: vaga.estado == 'confirmado'
                ? const Color(0xFF22C55E)
                : const Color(0xFFE65100),
          ),
        ),
      );
    } else if (isDisponivel) {
      borderColor = const Color(0xFF22C55E).withOpacity(0.4);
      bgColor = const Color(0xFF22C55E).withOpacity(0.05);
      horaColor = AppColors.accent;
      trailing = Switch(
        value: true,
        onChanged: (_) => onToggle(),
        activeColor: const Color(0xFF22C55E),
      );
    } else {
      // indisponivel
      borderColor = AppColors.border;
      bgColor = AppColors.surface;
      horaColor = AppColors.textMuted;
      trailing = Switch(
        value: false,
        onChanged: (_) => onToggle(),
        inactiveThumbColor: AppColors.textMuted,
        inactiveTrackColor: AppColors.border,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(children: [
        // Barra lateral colorida (estilo protótipo)
        Container(
          width: 3,
          height: 36,
          decoration: BoxDecoration(
            color: isOcupado
                ? AppColors.primary
                : isDisponivel
                    ? const Color(0xFF22C55E)
                    : AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vaga.hora,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: horaColor)),
              if (isOcupado && vaga.nomeUser != null)
                Text(vaga.nomeUser!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted))
              else if (isDisponivel)
                const Text('Vaga disponível',
                    style: TextStyle(fontSize: 12, color: Color(0xFF22C55E)))
              else
                const Text('Indisponível',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        trailing,
      ]),
    );
  }
}
