// lib/features/schedule/confirmar_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../common/services/vagas_service.dart';
import '../common/widgets/blood_drop.dart';
import '../common/widgets/app_bottom_nav.dart';

class ConfirmarScreen extends StatefulWidget {
  const ConfirmarScreen({super.key});
  @override
  State<ConfirmarScreen> createState() => _ConfirmarScreenState();
}

class _ConfirmarScreenState extends State<ConfirmarScreen> {
  final _vagasService = VagasService();
  bool _loading = false;
  bool _initialized = false;
  late Vaga _vaga;
  late String _centroNome;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _vaga = args?['vaga'] as Vaga;
      _centroNome = args?['centroNome'] as String? ?? 'Centro';
      _initialized = true;
    }
  }

  Future<void> _confirmar() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _vagasService.solicitarVaga(_vaga.id, uid);
      if (!mounted) return;
      _showSucesso();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao confirmar: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSucesso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Pedido enviado!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.accent)),
            const SizedBox(height: 8),
            const Text(
              'O seu pedido de agendamento foi enviado para o centro de saúde. Receberá uma notificação assim que o pedido for aceite.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamedAndRemoveUntil(context, AppRoutesUser.home, (_) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Ir para o início', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                const BloodDrop(size: 24),
                const SizedBox(width: 8),
                const Text('Confirmar Agendamento',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),

            // Stepper
            _buildStepper(),
            const SizedBox(height: 20),

            // Card de resumo
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    icon: Icons.location_on_outlined,
                    iconBg: AppColors.primary.withOpacity(0.1),
                    iconColor: AppColors.primary,
                    label: 'Localidade',
                    value: _centroNome,
                  ),
                  const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
                  _summaryRow(
                    icon: Icons.calendar_today_outlined,
                    iconBg: const Color(0xFF22C55E).withOpacity(0.1),
                    iconColor: const Color(0xFF22C55E),
                    label: 'Data e Hora',
                    value: '${_vaga.hora}  ·  ${_formatDate(_vaga.data)}',
                    badge: 'Vaga disponível',
                  ),
                  const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
                  _summaryRow(
                    icon: Icons.water_drop_outlined,
                    iconBg: AppColors.primary.withOpacity(0.08),
                    iconColor: AppColors.primary,
                    label: 'Tipo de Doação',
                    value: 'Sangue total',
                    sub: 'Duração estimada: 30 min',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Aviso
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFAC775)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFFBA7517)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Receberá uma notificação de confirmação e um lembrete 24h antes.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFBA7517), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Antes de chegar
            const Text('Antes de chegar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.primary, letterSpacing: 0.3)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _reqItem('Documento de identificação válido'),
                  _reqItem('Beber bastante água nas horas anteriores'),
                  _reqItem('Fazer uma refeição leve 2h antes'),
                  _reqItem('Dormir pelo menos 6h na noite anterior'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('VOLTAR',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _confirmar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('CONFIRMAR',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _summaryRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    String? sub,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted,
                    fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
                if (sub != null) Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FBF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC0DD97)),
                    ),
                    child: const Text('Vaga disponível',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF3B6D11))),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reqItem(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 6, height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
      ],
    ),
  );

  Widget _buildStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _step(1, false, done: true),
        _line(true),
        _step(2, false, done: true),
        _line(true),
        _step(3, true),
      ],
    );
  }

  Widget _step(int n, bool active, {bool done = false}) => Container(
    width: 32, height: 32,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: (active || done) ? AppColors.primary : AppColors.surface,
      border: Border.all(color: (active || done) ? AppColors.primary : AppColors.border, width: 1.5),
    ),
    child: Center(child: Text('$n',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: (active || done) ? Colors.white : AppColors.textMuted))),
  );

  Widget _line(bool active) => Container(
    width: 40, height: 1.5,
    color: active ? AppColors.primary : AppColors.border,
  );
}
