// lib/features/centro/gerir_vagas_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../widgets/blood_drop.dart';

const List<String> _horasDefault = [
  '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
  '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
];

class GerirVagasScreen extends StatefulWidget {
  const GerirVagasScreen({super.key});

  @override
  State<GerirVagasScreen> createState() => _GerirVagasScreenState();
}

class _GerirVagasScreenState extends State<GerirVagasScreen> {
  final String _centroId = FirebaseAuth.instance.currentUser!.uid;
  DateTime _diaSelected = DateTime.now();
  // hora → estado (disponivel | indisponivel | ocupada)
  Map<String, String> _slots = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _loading = true);
    final chave = DateFormat('yyyy-MM-dd').format(_diaSelected);
    final doc = await FirebaseFirestore.instance
        .collection('centros')
        .doc(_centroId)
        .collection('vagas')
        .doc(chave)
        .get();

    if (doc.exists && doc.data()?['slots'] != null) {
      _slots = Map<String, String>.from(doc.data()!['slots'] as Map);
      // Garante que todos os horários padrão existem
      for (final h in _horasDefault) {
        _slots.putIfAbsent(h, () => 'disponivel');
      }
    } else {
      _slots = {for (final h in _horasDefault) h: 'disponivel'};
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);
    final chave = DateFormat('yyyy-MM-dd').format(_diaSelected);
    await FirebaseFirestore.instance
        .collection('centros')
        .doc(_centroId)
        .collection('vagas')
        .doc(chave)
        .set({'slots': _slots}, SetOptions(merge: true));
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disponibilidade guardada.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggle(String hora) {
    if (_slots[hora] == 'ocupada') return; // não pode alterar vagas ocupadas
    setState(() {
      _slots[hora] =
          _slots[hora] == 'disponivel' ? 'indisponivel' : 'disponivel';
    });
  }

  @override
  Widget build(BuildContext context) {
    final horasOrdenadas = _slots.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const BloodDrop(size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Gerir Vagas',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Seletor de dia
            _buildSeletorDia(),
            const SizedBox(height: 12),

            // Legenda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _legenda(AppColors.success, 'Disponível'),
                  const SizedBox(width: 12),
                  _legenda(AppColors.border, 'Indisponível'),
                  const SizedBox(width: 12),
                  _legenda(AppColors.primary, 'Ocupado'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Lista de slots
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: horasOrdenadas.length,
                      itemBuilder: (context, i) {
                        final hora = horasOrdenadas[i];
                        final estado = _slots[hora]!;
                        final ocupada = estado == 'ocupada';

                        return GestureDetector(
                          onTap: ocupada ? null : () => _toggle(hora),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: estado == 'disponivel'
                                      ? AppColors.success
                                      : estado == 'ocupada'
                                          ? AppColors.primary
                                          : AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  hora,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  estado == 'disponivel'
                                      ? 'Disponível'
                                      : estado == 'ocupada'
                                          ? 'Ocupado'
                                          : 'Indisponível',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: estado == 'disponivel'
                                        ? AppColors.success
                                        : estado == 'ocupada'
                                            ? AppColors.primary
                                            : AppColors.textMuted,
                                  ),
                                ),
                                if (!ocupada) ...[
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: estado == 'disponivel',
                                    onChanged: (_) => _toggle(hora),
                                    activeThumbColor: AppColors.success,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Botão Guardar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving || _loading ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Guardar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeletorDia() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() =>
                  _diaSelected = _diaSelected.subtract(const Duration(days: 1)));
              _loadSlots();
            },
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _diaSelected,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) {
                setState(() => _diaSelected = picked);
                _loadSlots();
              }
            },
            child: Text(
              DateFormat("EEEE, d 'de' MMM yyyy", 'pt_PT')
                  .format(_diaSelected),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() =>
                  _diaSelected = _diaSelected.add(const Duration(days: 1)));
              _loadSlots();
            },
          ),
        ],
      ),
    );
  }

  Widget _legenda(Color cor, String label) => Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: cor)),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      );
}
