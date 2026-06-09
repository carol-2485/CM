// lib/features/schedule/questionario_screen.dart
//
// Questionário de aptidão para doação de sangue.
// Avalia a elegibilidade do utilizador com base em respostas sobre saúde.
// Integra com a OpenFDA API para verificar medicação contínua.
// A idade é lida automaticamente do perfil — não é pedida novamente.

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../auth/services/auth_service.dart';
import '../common/services/openfda_service.dart';
import '../common/widgets/app_bottom_nav.dart';
import '../common/widgets/blood_drop.dart';

/// Ecrã do Questionário de Aptidão para Doação de Sangue.
class QuestionarioScreen extends StatefulWidget {
  const QuestionarioScreen({super.key});

  @override
  State<QuestionarioScreen> createState() => _QuestionarioScreenState();
}

class _QuestionarioScreenState extends State<QuestionarioScreen> {
  // ── Controladores ─────────────────────────────────────────────────────────
  final _chaveFormulario = GlobalKey<FormState>();
  final _ctrlPeso = TextEditingController();
  final _ctrlMedicamento = TextEditingController();
  final _ctrlData = TextEditingController();

  // ── Serviços ──────────────────────────────────────────────────────────────
  final _servAutenticacao = AuthService();
  final _servFda = OpenFdaService();

  // ── Estado das perguntas ──────────────────────────────────────────────────
  bool? _jaDouSangue;
  bool? _teveFebre;
  bool? _temHepatite;
  bool? _usaMedicacao;
  bool _aVerificar = false;

  @override
  void dispose() {
    _ctrlPeso.dispose();
    _ctrlMedicamento.dispose();
    _ctrlData.dispose();
    super.dispose();
  }

  // ── Lógica de negócio ─────────────────────────────────────────────────────

  /// Valida as respostas e determina a aptidão do utilizador.
  /// A idade é obtida do perfil guardado — não é solicitada novamente.
  Future<void> _verificarAptidao() async {
    if (!_chaveFormulario.currentState!.validate()) return;

    // Valida que todas as perguntas de sim/não foram respondidas
    if (_jaDouSangue == null ||
        _teveFebre == null ||
        _temHepatite == null ||
        _usaMedicacao == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor responda a todas as perguntas.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _aVerificar = true);

    bool apto = true;
    String? motivo;

    // Regra 1: Idade (lida do perfil, não perguntada)
    final dadosUser = await _servAutenticacao.getUserData();
    final idadeStr = dadosUser?['idade']?.toString() ?? '0';
    final idade = int.tryParse(idadeStr) ?? 0;
    if (idade < 18 || idade > 65) {
      apto = false;
      motivo = 'A idade deve estar entre 18 e 65 anos.';
    }

    // Regra 2: Peso mínimo
    if (apto) {
      final peso =
          double.tryParse(_ctrlPeso.text.replaceAll(',', '.')) ?? 0;
      if (peso < 50) {
        apto = false;
        motivo = 'O peso mínimo para doação é 50 kg.';
      }
    }

    // Regra 3: Febre ou infecção recente
    if (apto && _teveFebre == true) {
      apto = false;
      motivo =
          'Febre ou sintomas de infecção nos últimos 30 dias contraindica a doação.';
    }

    // Regra 4: Doenças graves
    if (apto && _temHepatite == true) {
      apto = false;
      motivo =
          'Historial de Hepatite, HIV ou doença grave contraindica a doação.';
    }

    // Regra 5: Medicação — verifica via OpenFDA API
    if (apto && _usaMedicacao == true) {
      final nomeMed = _ctrlMedicamento.text.trim();
      if (nomeMed.isEmpty) {
        apto = false;
        motivo = 'Indique o nome do medicamento para validar a sua aptidão.';
      } else {
        final resultado = await _servFda.verificarMedicamento(nomeMed);
        if (resultado['contraindica'] == true) {
          apto = false;
          motivo = resultado['mensagem'] as String;
        }
      }
    }

    setState(() => _aVerificar = false);
    if (!mounted) return;

    // Guarda o resultado no Firestore
    await _servAutenticacao.updateEligibility(apto);
    if (!mounted) return;

    _mostrarResultado(apto, motivo);
  }

  /// Apresenta o diálogo com o resultado da avaliação de aptidão.
  void _mostrarResultado(bool apto, String? motivo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DialogoResultado(
        apto: apto,
        motivo: motivo,
        aoFechar: () {
          Navigator.pop(ctx);
          if (apto) {
            Navigator.pushReplacementNamed(context, AppRoutesUser.centros);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutesUser.home);
          }
        },
      ),
    );
  }

  // ── Interface ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _chaveFormulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                const _TituloQuestionario(),
                const SizedBox(height: 20),

                // Campo: Peso
                _CampoPeso(ctrl: _ctrlPeso),
                const SizedBox(height: 16),

                // Perguntas de sim/não
                _PerguntaSimNao(
                  pergunta: 'Já doou sangue antes?*',
                  valor: _jaDouSangue,
                  aoAlterar: (v) => setState(() => _jaDouSangue = v),
                ),
                _PerguntaSimNao(
                  pergunta:
                      'Teve febre ou sintomas de infecção nos últimos 30 dias?*',
                  valor: _teveFebre,
                  aoAlterar: (v) => setState(() => _teveFebre = v),
                ),
                _PerguntaSimNao(
                  pergunta: 'Tem Hepatite, HIV ou outra doença grave?*',
                  valor: _temHepatite,
                  aoAlterar: (v) => setState(() => _temHepatite = v),
                ),
                _PerguntaSimNao(
                  pergunta: 'Usa medicação contínua?*',
                  valor: _usaMedicacao,
                  aoAlterar: (v) => setState(() => _usaMedicacao = v),
                ),

                // Campo de medicamento (condicional)
                if (_usaMedicacao == true)
                  _CampoMedicamento(ctrl: _ctrlMedicamento),

                const SizedBox(height: 8),

                // Data da última doação
                _CampoDataDoacao(ctrl: _ctrlData),
                const SizedBox(height: 28),

                // Botão verificar
                _BotaoVerificar(
                  aVerificar: _aVerificar,
                  aoPremir: _verificarAptidao,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

// ── Widgets internos ─────────────────────────────────────────────────────────

/// Título do questionário com ícone de gota.
class _TituloQuestionario extends StatelessWidget {
  const _TituloQuestionario();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BloodDrop(size: 28),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Questionário de\nAptidão para Doação',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

/// Campo de texto para o peso corporal do utilizador.
class _CampoPeso extends StatelessWidget {
  final TextEditingController ctrl;
  const _CampoPeso({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _decoracaoCampo('Peso (Kg)*'),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Campo obrigatório';
        final p = double.tryParse(v.replaceAll(',', '.'));
        if (p == null || p < 50) return 'Peso mínimo é 50 kg';
        return null;
      },
    );
  }
}

/// Campo de texto para o nome do medicamento (aparece quando o utilizador
/// indica que usa medicação contínua).
class _CampoMedicamento extends StatelessWidget {
  final TextEditingController ctrl;
  const _CampoMedicamento({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          decoration: _decoracaoCampo(
            'Nome do medicamento *',
            icone: Icons.medication_outlined,
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Indique o nome do medicamento' : null,
        ),
        const SizedBox(height: 6),
        // Aviso informativo sobre a verificação via OpenFDA
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'A app verifica o medicamento contra a lista do IPST e a OpenFDA API.',
                  style: TextStyle(fontSize: 11, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Selector de data da última doação.
class _CampoDataDoacao extends StatelessWidget {
  final TextEditingController ctrl;
  const _CampoDataDoacao({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      onTap: () async {
        final escolhida = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 90)),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (escolhida != null) {
          ctrl.text =
              '${escolhida.day.toString().padLeft(2, '0')}/${escolhida.month.toString().padLeft(2, '0')}/${escolhida.year}';
        }
      },
      decoration: _decoracaoCampo(
        'Data da última doação',
        icone: Icons.calendar_month_outlined,
        ehSufixo: true,
      ),
    );
  }
}

/// Par de radio buttons "Sim / Não" para uma pergunta fechada.
class _PerguntaSimNao extends StatelessWidget {
  final String pergunta;
  final bool? valor;
  final void Function(bool) aoAlterar;

  const _PerguntaSimNao({
    required this.pergunta,
    required this.valor,
    required this.aoAlterar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pergunta,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Radio<bool>(
                  value: true,
                  // ignore: deprecated_member_use
                  groupValue: valor,
                  // ignore: deprecated_member_use
                  onChanged: (v) => aoAlterar(v!)),
              const Text('Sim',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(width: 24),
              Radio<bool>(
                  value: false,
                  // ignore: deprecated_member_use
                  groupValue: valor,
                  // ignore: deprecated_member_use
                  onChanged: (v) => aoAlterar(v!)),
              const Text('Não',
                  style: TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botão de verificação de aptidão.
class _BotaoVerificar extends StatelessWidget {
  final bool aVerificar;
  final VoidCallback aoPremir;

  const _BotaoVerificar({
    required this.aVerificar,
    required this.aoPremir,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: aVerificar ? null : aoPremir,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: aVerificar
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Verificar Aptidão',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
      ),
    );
  }
}

/// Diálogo com o resultado da avaliação de aptidão.
class _DialogoResultado extends StatelessWidget {
  final bool apto;
  final String? motivo;
  final VoidCallback aoFechar;

  const _DialogoResultado({
    required this.apto,
    required this.motivo,
    required this.aoFechar,
  });

  @override
  Widget build(BuildContext context) {
    final cor = apto ? const Color(0xFF22C55E) : AppColors.error;

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone de resultado
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            child: Icon(
              apto ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),

          // Mensagem principal
          Text(
            apto
                ? 'Está apto para doar sangue!'
                : 'Não está apto de momento.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700),
          ),

          // Motivo (se inapto)
          if (motivo != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                motivo!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: cor, height: 1.4),
              ),
            ),
          ],

          // Nota adicional para inaptos
          if (!apto) ...[
            const SizedBox(height: 8),
            const Text(
              'Para mais informações contacte um profissional de saúde ou o IPST.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: aoFechar,
            child: Text(
              apto ? 'Ver centros de doação' : 'Voltar ao início',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Funções auxiliares ────────────────────────────────────────────────────────

/// Decoração padrão dos campos de texto do questionário.
InputDecoration _decoracaoCampo(
  String dica, {
  IconData? icone,
  bool ehSufixo = false,
}) {
  return InputDecoration(
    hintText: dica,
    prefixIcon: icone != null && !ehSufixo
        ? Icon(icone, color: AppColors.primary)
        : null,
    suffixIcon: ehSufixo && icone != null
        ? Icon(icone, color: AppColors.primary)
        : null,
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5)),
  );
}
