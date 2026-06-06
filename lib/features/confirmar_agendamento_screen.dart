// lib/features/confirmar_agendamento_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/blood_drop.dart';

const List<String> _horasDefault = [
  '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
  '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
];

class ConfirmarAgendamentoScreen extends StatefulWidget {
  const ConfirmarAgendamentoScreen({super.key});

  @override
  State<ConfirmarAgendamentoScreen> createState() =>
      _ConfirmarAgendamentoScreenState();
}

class _ConfirmarAgendamentoScreenState
    extends State<ConfirmarAgendamentoScreen> {
  bool _saving = false;

  Map<String, dynamic> get _args =>
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

  Future<void> _confirmar() async {
    final centroId = _args['centroId'] as String;
    final dataKey  = _args['dataKey']  as String;
    final hora     = _args['hora']     as String;
    final uid      = FirebaseAuth.instance.currentUser?.uid ?? '';

    setState(() => _saving = true);
    try {
      final db = FirebaseFirestore.instance;
      final vagaRef = db
          .collection('centros')
          .doc(centroId)
          .collection('vagas')
          .doc(dataKey);

      await db.runTransaction((tx) async {
        final snap = await tx.get(vagaRef);
        final Map<String, String> slots = snap.exists && snap.data()?['slots'] != null
            ? Map<String, String>.from(snap.data()!['slots'] as Map)
            : {};
        // Preenche horários padrão que ainda não existam
        for (final h in _horasDefault) {
          slots.putIfAbsent(h, () => 'disponivel');
        }

        if ((slots[hora] ?? 'disponivel') != 'disponivel') {
          throw Exception('vaga-indisponivel');
        }

        slots[hora] = 'ocupada';
        tx.set(vagaRef, {'slots': slots}, SetOptions(merge: true));

        final agRef = db.collection('agendamentos').doc();
        tx.set(agRef, {
          'uid': uid,
          'centroId': centroId,
          'data': dataKey,
          'hora': hora,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento confirmado!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutesUser.home, (r) => false);
      }
    } on Exception catch (e) {
      if (mounted) {
        final msg = e.toString().contains('vaga-indisponivel')
            ? 'Esta vaga já foi ocupada. Escolha outro horário.'
            : 'Erro ao confirmar. Tente novamente.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    final centro = args['centro'] as String? ?? '';
    final data   = args['data']   as String? ?? '';
    final hora   = args['hora']   as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Row(
                children: [
                  const BloodDrop(size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Confirmar Agendamento',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stepper 1-2-3
              _buildStepper(),
              const SizedBox(height: 24),

              // Card de resumo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.location_on_outlined, 'Localidade', centro),
                    const Divider(height: 24, color: AppColors.border),
                    _infoRow(Icons.calendar_today_outlined, 'Data e Hora',
                        '$hora  ·  $data'),
                    const Divider(height: 24, color: AppColors.border),
                    _infoRow(Icons.water_drop_outlined, 'Tipo de Doação',
                        'Sangue total'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Aviso "Antes de chegar"
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Antes de chegar',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 8),
                    _AvisoItem('Documento de identificação válido'),
                    _AvisoItem('Beber bastante água nas horas anteriores'),
                    _AvisoItem('Fazer uma refeição leve 2h antes'),
                    _AvisoItem('Dormir pelo menos 6h na noite anterior'),
                  ],
                ),
              ),

              const Spacer(),

              // Botão Confirmar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _confirmar,
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
                          'Confirmar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent)),
          ],
        ),
      ],
    );
  }

  Widget _buildStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _step(1, false),
        _line(true),
        _step(2, false),
        _line(true),
        _step(3, true),
      ],
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
}

class _AvisoItem extends StatelessWidget {
  final String texto;
  const _AvisoItem(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Text('• ',
              style: TextStyle(color: AppColors.primary, fontSize: 13)),
          Expanded(
            child: Text(texto,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
