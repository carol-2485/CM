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

  _Vaga({required this.id, required this.hora, required this.estado});
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

  // Horários padrão 09:00 - 17:30 de 30 em 30 min
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
    // Verifica se existe documento com ID = UID
    final doc = await FirebaseFirestore.instance.collection('centros').doc(uid).get();
    if (doc.exists) {
      _centroId = uid;
    } else {
      // Procura pelo campo uid
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

      if (snap.docs.isEmpty) {
        // Gera vagas padrão para este dia
        await _gerarVagasPadrao(key);
        final snap2 = await _db
            .collection('vagas')
            .where('centroId', isEqualTo: _centroId)
            .where('dataKey', isEqualTo: key)
            .get();
        _vagas = snap2.docs.map((d) => _Vaga(
          id: d.id,
          hora: d['hora'],
          estado: d['estado'],
        )).toList();
      } else {
        _vagas = snap.docs.map((d) => _Vaga(
          id: d.id,
          hora: d['hora'],
          estado: d['estado'],
        )).toList();
      }
      _vagas.sort((a, b) => a.hora.compareTo(b.hora));
    } catch (e) {
      debugPrint('Erro ao carregar vagas: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _gerarVagasPadrao(String dataKey) async {
    final batch = _db.batch();
    for (final hora in _horariosDefault) {
      final ref = _db.collection('vagas').doc();
      batch.set(ref, {
        'centroId': _centroId,
        'dataKey': dataKey,
        'hora': hora,
        'estado': 'disponivel',
        'userId': null,
      });
    }
    await batch.commit();
  }

  Future<void> _toggleVaga(_Vaga vaga) async {
    if (vaga.estado == 'ocupado') return;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const BloodDrop(size: 22),
              const SizedBox(width: 8),
              const Text('Gerir Vagas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ]),
          ),
          const SizedBox(height: 12),

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
              _legend(AppColors.border, 'Indisponível'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _vagas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
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
    final isOcupado = vaga.estado == 'ocupado';
    final isDisponivel = vaga.estado == 'disponivel';
    final borderColor = isOcupado ? AppColors.primary : isDisponivel ? const Color(0xFF22C55E) : AppColors.border;
    final labelColor = isOcupado ? AppColors.primary : isDisponivel ? const Color(0xFF22C55E) : AppColors.textMuted;
    final label = isOcupado ? 'Ocupado' : isDisponivel ? 'Disponível' : 'Indisponível';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(children: [
        Text(vaga.hora,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent)),
        const SizedBox(width: 14),
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 13, color: labelColor, fontWeight: FontWeight.w500))),
        if (!isOcupado)
          Switch(
            value: isDisponivel,
            onChanged: (_) => onToggle(),
            activeColor: const Color(0xFF22C55E),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.border.withOpacity(0.5),
          ),
      ]),
    );
  }
}
