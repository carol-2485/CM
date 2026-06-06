// lib/features/agenda_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/blood_drop.dart';

// Horários padrão quando o admin ainda não configurou o dia
const List<String> _horasDefault = [
  '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
  '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
];

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  Map<String, dynamic> get _args =>
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  String get _centroNome => _args['centroNome'] as String? ?? '';
  String get _centroId   => _args['centroId']   as String? ?? '';

  DateTime _mesAtual   = DateTime.now();
  DateTime _diaSelected = DateTime.now();
  List<Map<String, dynamic>> _vagas = [];
  bool _loadingVagas = true;
  String? _horaSelected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadVagas();
  }

  Future<void> _loadVagas() async {
    setState(() { _loadingVagas = true; _horaSelected = null; });
    final chave = DateFormat('yyyy-MM-dd').format(_diaSelected);
    final doc = await FirebaseFirestore.instance
        .collection('centros')
        .doc(_centroId)
        .collection('vagas')
        .doc(chave)
        .get();

    Map<String, String> slots;
    if (doc.exists && doc.data()?['slots'] != null) {
      slots = Map<String, String>.from(doc.data()!['slots'] as Map);
    } else {
      slots = {};
    }
    // Garante que todos os horários padrão existem no mapa
    for (final h in _horasDefault) {
      slots.putIfAbsent(h, () => 'disponivel');
    }

    if (mounted) {
      setState(() {
        _vagas = slots.entries
            .map((e) => {'hora': e.key, 'estado': e.value})
            .toList()
          ..sort((a, b) => (a['hora'] as String).compareTo(b['hora'] as String));
        _loadingVagas = false;
      });
    }
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
                    'Agenda',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Stepper 1-2-3
            _buildStepper(),
            const SizedBox(height: 12),

            // Calendário
            _buildCalendario(),
            const SizedBox(height: 8),

            // Dia selecionado + legenda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat("EEEE, d 'de' MMM yyyy", 'pt_PT')
                        .format(_diaSelected),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _legenda(AppColors.success, 'Disponível'),
                      const SizedBox(width: 12),
                      _legenda(AppColors.primary, 'Ocupado'),
                      const SizedBox(width: 12),
                      _legenda(AppColors.border, 'Indisponível'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Lista de vagas
            Expanded(
              child: _loadingVagas
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _vagas.length,
                itemBuilder: (context, i) {
                  final v = _vagas[i];
                  final isDisp = v['estado'] == 'disponivel';
                  final isSelected = _horaSelected == v['hora'];

                  return GestureDetector(
                    onTap: isDisp
                        ? () => setState(() => _horaSelected = v['hora'])
                        : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            v['hora'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDisp
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _corEstado(v['estado']),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _labelEstado(v['estado']),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isDisp
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: _corEstado(v['estado']),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_horaSelected != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutesUser.confirmarAgendamento,
                      arguments: {
                        'centro': _centroNome,
                        'centroId': _centroId,
                        'data': DateFormat('dd/MM/yyyy').format(_diaSelected),
                        'dataKey': DateFormat('yyyy-MM-dd').format(_diaSelected),
                        'hora': _horaSelected!,
                      },
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Confirmar',
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  // ── Calendário ────────────────────────────────────────────
  Widget _buildCalendario() {
    final primeiroDia =
        DateTime(_mesAtual.year, _mesAtual.month, 1);
    final offsetInicio = primeiroDia.weekday % 7; // Dom=0
    final diasNoMes =
        DateTime(_mesAtual.year, _mesAtual.month + 1, 0).day;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Navegação mês
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () => setState(() => _mesAtual =
                    DateTime(_mesAtual.year, _mesAtual.month - 1)),
              ),
              Text(
                DateFormat('MMMM yyyy', 'pt_PT').format(_mesAtual),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.accent,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () => setState(() => _mesAtual =
                    DateTime(_mesAtual.year, _mesAtual.month + 1)),
              ),
            ],
          ),
          // Cabeçalho dias da semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']
                .map((d) => SizedBox(
                      width: 32,
                      child: Text(d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // Grade de dias
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: offsetInicio + diasNoMes,
            itemBuilder: (context, index) {
              if (index < offsetInicio) return const SizedBox();
              final dia = index - offsetInicio + 1;
              final data =
                  DateTime(_mesAtual.year, _mesAtual.month, dia);
              final isSelected = _diaSelected.year == data.year &&
                  _diaSelected.month == data.month &&
                  _diaSelected.day == data.day;
              final isHoje = DateTime.now().year == data.year &&
                  DateTime.now().month == data.month &&
                  DateTime.now().day == data.day;

              return GestureDetector(
                onTap: () {
                  setState(() => _diaSelected = data);
                  _loadVagas();
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      '$dia',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected || isHoje ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : isHoje
                                ? AppColors.primary
                                : AppColors.accent,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Stepper ──────────────────────────────────────────────
  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _step(1, false),
          _line(true),
          _step(2, true),
          _line(false),
          _step(3, false),
        ],
      ),
    );
  }

  Widget _step(int n, bool active) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.primary : AppColors.surface,
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
              width: 1.5),
        ),
        child: Center(
          child: Text('$n',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.textMuted)),
        ),
      );

  Widget _line(bool active) => Container(
        width: 40,
        height: 1.5,
        color: active ? AppColors.primary : AppColors.border,
      );

  // ── Helpers ──────────────────────────────────────────────
  Color _corEstado(String estado) {
    switch (estado) {
      case 'disponivel':
        return AppColors.success;
      case 'ocupada':
        return AppColors.primary;
      default:
        return AppColors.border;
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'disponivel':
        return 'Vaga disponível';
      case 'ocupada':
        return 'Vaga ocupada';
      default:
        return 'Indisponível';
    }
  }

  Widget _legenda(Color cor, String label) => Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: cor)),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      );
}
