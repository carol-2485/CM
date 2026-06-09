// lib/features/schedule/confirmar_screen.dart
//
// Ecrã de confirmação de agendamento de doação de sangue.
// Apresenta o resumo da marcação e envia o pedido ao centro de saúde.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../common/services/vagas_service.dart';
import '../common/widgets/blood_drop.dart';
import '../common/widgets/app_bottom_nav.dart';
import 'widgets/indicador_passos.dart';

/// Ecrã de confirmação final antes de submeter o pedido de agendamento.
class ConfirmarScreen extends StatefulWidget {
  const ConfirmarScreen({super.key});

  @override
  State<ConfirmarScreen> createState() => _ConfirmarScreenState();
}

class _ConfirmarScreenState extends State<ConfirmarScreen> {
  // ── Serviços ─────────────────────────────────────────────────────────────
  final _vagasService = VagasService();

  // ── Estado ───────────────────────────────────────────────────────────────
  bool _aCarregar = false;
  bool _inicializado = false;
  late Vaga _vaga;
  late String _nomeCentro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _vaga = args?['vaga'] as Vaga;
      _nomeCentro = args?['centroNome'] as String? ?? 'Centro';
      _inicializado = true;
    }
  }

  // ── Lógica de negócio ─────────────────────────────────────────────────────

  /// Solicita a vaga ao centro de saúde e navega para o ecrã inicial.
  Future<void> _confirmarAgendamento() async {
    setState(() => _aCarregar = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _vagasService.solicitarVaga(_vaga.id, uid);
      if (!mounted) return;
      _mostrarSucesso();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao confirmar: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _aCarregar = false);
    }
  }

  /// Apresenta diálogo de sucesso após submissão do pedido.
  void _mostrarSucesso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoSucesso(
        aoFechar: () {
          Navigator.pop(context); // fecha diálogo
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutesUser.home,
            (_) => false,
          );
        },
      ),
    );
  }

  /// Formata uma data para o formato DD/MM/AAAA.
  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Row(
              children: [
                BloodDrop(size: 24),
                SizedBox(width: 8),
                Text(
                  'Confirmar Agendamento',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Indicador de passos (passo 3 de 3)
            const IndicadorPassos(passoActual: 3),
            const SizedBox(height: 20),

            // Resumo do agendamento
            _CartaoResumo(
              nomeCentro: _nomeCentro,
              hora: _vaga.hora,
              data: _formatarData(_vaga.data),
            ),
            const SizedBox(height: 16),

            // Aviso de notificação
            const _AvisoNotificacao(),
            const SizedBox(height: 16),

            // Instruções de preparação
            const _SecaoPreparacao(),
            const SizedBox(height: 24),

            // Botões de acção
            _BotoesAcao(
              aCarregar: _aCarregar,
              aoVoltar: () => Navigator.pop(context),
              aoConfirmar: _confirmarAgendamento,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

/// Cartão com resumo dos dados do agendamento.
class _CartaoResumo extends StatelessWidget {
  final String nomeCentro;
  final String hora;
  final String data;

  const _CartaoResumo({
    required this.nomeCentro,
    required this.hora,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _LinhaResumo(
            icone: Icons.location_on_outlined,
            corFundo: AppColors.primary.withValues(alpha: 0.1),
            corIcone: AppColors.primary,
            rotulo: 'Localidade',
            valor: nomeCentro,
          ),
          const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
          _LinhaResumo(
            icone: Icons.calendar_today_outlined,
            corFundo: const Color(0xFF22C55E).withValues(alpha: 0.1),
            corIcone: const Color(0xFF22C55E),
            rotulo: 'Data e Hora',
            valor: '$hora  ·  $data',
            badge: 'Vaga disponível',
          ),
          const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
          _LinhaResumo(
            icone: Icons.water_drop_outlined,
            corFundo: AppColors.primary.withValues(alpha: 0.08),
            corIcone: AppColors.primary,
            rotulo: 'Tipo de Doação',
            valor: 'Sangue total',
            sub: 'Duração estimada: 30 min',
          ),
        ],
      ),
    );
  }
}

/// Linha individual do cartão de resumo.
class _LinhaResumo extends StatelessWidget {
  final IconData icone;
  final Color corFundo;
  final Color corIcone;
  final String rotulo;
  final String valor;
  final String? sub;
  final String? badge;

  const _LinhaResumo({
    required this.icone,
    required this.corFundo,
    required this.corIcone,
    required this.rotulo,
    required this.valor,
    this.sub,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: corFundo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: corIcone, size: 20),
          ),
          const SizedBox(width: 14),

          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                if (sub != null)
                  Text(sub!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  _BadgeDisponivel(texto: badge!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge verde "Vaga disponível".
class _BadgeDisponivel extends StatelessWidget {
  final String texto;
  const _BadgeDisponivel({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FBF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC0DD97)),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF3B6D11),
        ),
      ),
    );
  }
}

/// Aviso sobre notificação de confirmação.
class _AvisoNotificacao extends StatelessWidget {
  const _AvisoNotificacao();

  @override
  Widget build(BuildContext context) {
    return Container(
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
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFBA7517),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Secção com instruções de preparação para a doação.
class _SecaoPreparacao extends StatelessWidget {
  const _SecaoPreparacao();

  static const _instrucoes = [
    'Documento de identificação válido',
    'Beber bastante água nas horas anteriores',
    'Fazer uma refeição leve 2h antes',
    'Dormir pelo menos 6h na noite anterior',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Antes de chegar',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: _instrucoes
                .map((instrucao) => _ItemPreparacao(texto: instrucao))
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// Item individual da lista de preparação.
class _ItemPreparacao extends StatelessWidget {
  final String texto;
  const _ItemPreparacao({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Par de botões Voltar/Confirmar.
class _BotoesAcao extends StatelessWidget {
  final bool aCarregar;
  final VoidCallback aoVoltar;
  final VoidCallback aoConfirmar;

  const _BotoesAcao({
    required this.aCarregar,
    required this.aoVoltar,
    required this.aoConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: aoVoltar,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'VOLTAR',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: aCarregar ? null : aoConfirmar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: aCarregar
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'CONFIRMAR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Diálogo de sucesso após submissão do pedido de agendamento.
class _DialogoSucesso extends StatelessWidget {
  final VoidCallback aoFechar;
  const _DialogoSucesso({required this.aoFechar});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone de sucesso
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pedido enviado!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'O seu pedido de agendamento foi enviado para o centro de saúde. Receberá uma notificação assim que o pedido for aceite.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: aoFechar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Ir para o início',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
