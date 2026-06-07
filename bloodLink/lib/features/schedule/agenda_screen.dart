// lib/features/schedule/agenda_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../common/services/vagas_service.dart';
import '../common/widgets/blood_drop.dart';
import '../common/widgets/app_bottom_nav.dart';
import 'widgets/indicador_passos.dart';

/// Horários padrão de funcionamento por dia da semana.
/// Usado quando o centro não tem horário definido no Firestore.
const _horariosPadrao = {
  'segunda':  ['09:00','09:30','10:00','10:30','11:00','11:30','12:00','12:30','13:00','13:30','14:00','14:30','15:00','15:30','16:00','16:30','17:00','17:30'],
  'terca':    ['09:00','09:30','10:00','10:30','11:00','11:30','12:00','12:30','13:00','13:30','14:00','14:30','15:00','15:30','16:00','16:30','17:00','17:30'],
  'quarta':   ['09:00','09:30','10:00','10:30','11:00','11:30','12:00','12:30','13:00','13:30','14:00','14:30','15:00','15:30','16:00','16:30','17:00','17:30'],
  'quinta':   ['09:00','09:30','10:00','10:30','11:00','11:30','12:00','12:30','13:00','13:30','14:00','14:30','15:00','15:30','16:00','16:30','17:00','17:30'],
  'sexta':    ['09:00','09:30','10:00','10:30','11:00','11:30','12:00','12:30','13:00','13:30','14:00','14:30','15:00','15:30','16:00','16:30','17:00','17:30'],
  'sabado':   ['09:00','09:30','10:00','10:30','11:00','11:30','12:00','12:30'],
  'domingo':  [], // encerrado por defeito
};

/// Converte o weekday do Dart (1=Segunda, 7=Domingo) para a chave do mapa.
String _chaveDiaSemana(int weekday) {
  const dias = ['segunda','terca','quarta','quinta','sexta','sabado','domingo'];
  return dias[(weekday - 1).clamp(0, 6)];
}

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});
  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _vagasService = VagasService();
  DateTime _selectedDate = DateTime.now();
  List<Vaga> _vagas = [];
  bool _loading = false;
  Vaga? _selectedVaga;
  late String _centroId;
  late String _centroNome;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _centroId = args?['centroId'] as String? ?? '';
      _centroNome = args?['centroNome'] as String? ?? 'Centro';
      _initialized = true;
      _loadVagas();
    }
  }

  Future<void> _loadVagas() async {
    if (_centroId.isEmpty) return;
    setState(() { _loading = true; _selectedVaga = null; });

    final chave = VagasService.chaveData(_selectedDate);
    final db = FirebaseFirestore.instance;

    // Verifica se já existem vagas para este dia
    var snap = await db
        .collection('vagas')
        .where('centroId', isEqualTo: _centroId)
        .where('dataKey', isEqualTo: chave)
        .get();

    // Se não existirem, gera automaticamente com base no horário do centro
    if (snap.docs.isEmpty) {
      await _gerarVagasParaDia(_selectedDate, chave, db);
      snap = await db
          .collection('vagas')
          .where('centroId', isEqualTo: _centroId)
          .where('dataKey', isEqualTo: chave)
          .get();
    }

    final todasVagas = snap.docs.map(Vaga.fromFirestore).toList()
      ..sort((a, b) => a.hora.compareTo(b.hora));

    // Filtra horas já passadas quando é hoje
    final agora = DateTime.now();
    final ehHoje = _selectedDate.year == agora.year &&
        _selectedDate.month == agora.month &&
        _selectedDate.day == agora.day;

    final vagas = ehHoje
        ? todasVagas.where((v) {
            final partes = v.hora.split(':');
            if (partes.length != 2) return true;
            final horaVaga = DateTime(agora.year, agora.month, agora.day,
                int.parse(partes[0]), int.parse(partes[1]));
            return horaVaga.isAfter(agora);
          }).toList()
        : todasVagas;

    if (mounted) setState(() { _vagas = vagas; _loading = false; });
  }

  /// Gera vagas para um dia com base no horário de funcionamento do centro.
  /// Se o centro tiver o campo 'horario' no Firestore, usa-o.
  /// Caso contrário usa os horários padrão.
  Future<void> _gerarVagasParaDia(
      DateTime dia, String chave, FirebaseFirestore db) async {
    // Determina o dia da semana
    final chaveDia = _chaveDiaSemana(dia.weekday);

    // Tenta ler o horário do centro no Firestore
    List<String> horarios = List<String>.from(_horariosPadrao[chaveDia] ?? []);
    try {
      final centroDoc =
          await db.collection('centros').doc(_centroId).get();
      final horarioMapa =
          centroDoc.data()?['horario'] as Map<String, dynamic>?;
      if (horarioMapa != null) {
        final valorDia = horarioMapa[chaveDia] as String?;
        if (valorDia == null || valorDia == 'Encerrado') {
          horarios = []; // encerrado
        } else {
          // Formato esperado: '09:00 - 18:00'
          horarios = _gerarSlotsDeIntervalo(valorDia);
        }
      }
    } catch (_) {}

    if (horarios.isEmpty) return; // centro encerrado neste dia

    // Cria as vagas em batch
    final batch = db.batch();
    for (final hora in horarios) {
      final ref = db.collection('vagas').doc();
      batch.set(ref, {
        'centroId': _centroId,
        'dataKey': chave,
        'hora': hora,
        'estado': 'disponivel',
        'userId': null,
      });
    }
    await batch.commit();
  }

  /// Gera slots de 30 em 30 minutos a partir de um intervalo 'HH:mm - HH:mm'.
  List<String> _gerarSlotsDeIntervalo(String intervalo) {
    try {
      final partes = intervalo.split(' - ');
      if (partes.length != 2) return [];
      final inicioP = partes[0].trim().split(':');
      final fimP = partes[1].trim().split(':');
      final inicio = TimeOfDay(
          hour: int.parse(inicioP[0]), minute: int.parse(inicioP[1]));
      final fim = TimeOfDay(
          hour: int.parse(fimP[0]), minute: int.parse(fimP[1]));

      final slots = <String>[];
      var h = inicio.hour;
      var m = inicio.minute;
      while (h < fim.hour || (h == fim.hour && m < fim.minute)) {
        slots.add(
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
        m += 30;
        if (m >= 60) { m -= 60; h++; }
      }
      return slots;
    } catch (_) {
      return [];
    }
  }

  void _onDaySelected(DateTime day) {
    setState(() => _selectedDate = day);
    _loadVagas();
  }

  void _confirmar() {
    if (_selectedVaga == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Seleccione um horário disponível.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    Navigator.pushNamed(context, AppRoutesUser.confirmar, arguments: {
      'vaga': _selectedVaga!,
      'centroNome': _centroNome,
    });
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
              const Text('Agenda',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ]),
          ),
          const SizedBox(height: 8),
          _buildStepper(),
          const SizedBox(height: 10),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calendário
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _CalendarioWidget(
                      selectedDate: _selectedDate,
                      onDaySelected: _onDaySelected,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Data + legenda
                  Text(_formatDate(_selectedDate), style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  Row(children: [
                    _legend(const Color(0xFF22C55E), 'Disponível'),
                    const SizedBox(width: 12),
                    _legend(AppColors.primary, 'Ocupado'),
                    const SizedBox(width: 12),
                    _legend(const Color(0xFFB8A898), 'Indisponível'),
                  ]),
                  const SizedBox(height: 10),

                  // Vagas
                  if (_loading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ))
                  else if (_vagas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Sem vagas disponíveis neste dia.',
                          style: TextStyle(color: AppColors.textMuted))),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _vagas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (ctx, i) => _VagaTile(
                        vaga: _vagas[i],
                        isSelected: _selectedVaga?.id == _vagas[i].id,
                        onTap: () {
                          if (_vagas[i].estado == 'disponivel') {
                            setState(() => _selectedVaga = _vagas[i]);
                          }
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Botões
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('VOLTAR', style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirmar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('CONFIRMAR', style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  String _formatDate(DateTime d) {
    const dias = ['Domingo','Segunda-feira','Terça-feira','Quarta-feira','Quinta-feira','Sexta-feira','Sábado'];
    const meses = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    return '${dias[d.weekday % 7]}, ${d.day} de ${meses[d.month - 1]} ${d.year}';
  }

  Widget _legend(Color color, String label) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
  ]);

  Widget _buildStepper() => const IndicadorPassos(passoActual: 2);
}

// ── Calendário ─────────────────────────────────────────────────────────────

class _CalendarioWidget extends StatefulWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDaySelected;
  const _CalendarioWidget({required this.selectedDate, required this.onDaySelected});

  @override
  State<_CalendarioWidget> createState() => _CalendarioWidgetState();
}

class _CalendarioWidgetState extends State<_CalendarioWidget> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = DateTime(_month.year, _month.month, 1).weekday % 7;
    const meses = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho',
        'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.chevron_left, color: AppColors.accent, size: 20),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
          Expanded(child: Text('${meses[_month.month - 1]} ${_month.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent))),
          IconButton(icon: const Icon(Icons.chevron_right, color: AppColors.accent, size: 20),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
        ]),
        const SizedBox(height: 6),
        Row(children: ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb']
            .map((d) => Expanded(child: Center(child: Text(d,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)))))
            .toList()),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisExtent: 34),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (ctx, i) {
            if (i < startWeekday) return const SizedBox();
            final day = DateTime(_month.year, _month.month, i - startWeekday + 1);
            final isToday = day.year == hoje.year && day.month == hoje.month && day.day == hoje.day;
            final isSel = day.year == widget.selectedDate.year &&
                day.month == widget.selectedDate.month && day.day == widget.selectedDate.day;
            final isPast = day.isBefore(DateTime(hoje.year, hoje.month, hoje.day));
            return GestureDetector(
              onTap: isPast ? null : () => widget.onDaySelected(day),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: isSel ? AppColors.primary : (isToday ? AppColors.primary.withOpacity(0.15) : null)),
                child: Center(child: Text('${day.day}', style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel || isToday ? FontWeight.w700 : FontWeight.normal,
                  color: isSel ? Colors.white : (isPast ? AppColors.border : AppColors.accent),
                ))),
              ),
            );
          },
        ),
      ]),
    );
  }
}

// ── Tile de vaga — estilo protótipo (linha colorida simples) ───────────────

class _VagaTile extends StatelessWidget {
  final Vaga vaga;
  final bool isSelected;
  final VoidCallback onTap;
  const _VagaTile({required this.vaga, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDisponivel = vaga.estado == 'disponivel';
    final isOcupado = vaga.estado == 'ocupado' || vaga.estado == 'confirmado' || vaga.estado == 'pendente';
    final isIndisponivel = vaga.estado == 'indisponivel';

    // Cores base por estado
    final Color dotColor = isDisponivel
        ? const Color(0xFF22C55E)
        : isOcupado ? AppColors.primary : const Color(0xFFB8A898);

    final Color textColor = isDisponivel
        ? const Color(0xFF22C55E)
        : isOcupado ? AppColors.primary : const Color(0xFFB8A898);

    final String label = isDisponivel
        ? 'Vaga disponível'
        : isOcupado ? 'Vaga ocupada' : 'Indisponível';

    // Fundo colorido suave por estado
    Color bgColor;
    Color borderColor;
    if (isSelected) {
      bgColor = AppColors.primary.withOpacity(0.10);
      borderColor = AppColors.primary;
    } else if (isDisponivel) {
      bgColor = const Color(0xFF22C55E).withOpacity(0.07);
      borderColor = const Color(0xFF22C55E).withOpacity(0.35);
    } else if (isIndisponivel) {
      bgColor = const Color(0xFFB8A898).withOpacity(0.08);
      borderColor = const Color(0xFFB8A898).withOpacity(0.35);
    } else {
      // ocupado
      bgColor = AppColors.primary.withOpacity(0.05);
      borderColor = AppColors.primary.withOpacity(0.25);
    }

    return GestureDetector(
      onTap: isDisponivel ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(children: [
          SizedBox(
            width: 48,
            child: Text(vaga.hora, style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: isDisponivel ? AppColors.accent : textColor)),
          ),
          Container(width: 8, height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(
              fontSize: 13, color: textColor, fontWeight: FontWeight.w600))),
          if (isSelected)
            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
        ]),
      ),
    );
  }
}
