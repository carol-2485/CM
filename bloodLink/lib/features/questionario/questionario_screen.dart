// lib/features/schedule/questionario_screen.dart
//
// Questionário de aptidão para doação de sangue.
// Avalia a elegibilidade do utilizador com base em respostas sobre saúde.
// Integra com a OpenFDA API para verificar medicação contínua.
// A idade é lida automaticamente do perfil — não é pedida novamente.

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/questionario/widgets/botao_verificar.dart';
import 'package:flutter_application_1/features/questionario/widgets/campo_peso.dart';
import 'package:flutter_application_1/features/questionario/widgets/resultado.dart';
import 'package:flutter_application_1/features/questionario/widgets/titulo_questionario.dart';
import 'package:flutter_application_1/features/questionario/widgets/pergunta_sim_nao.dart';
import 'package:flutter_application_1/features/schedule/widgets/campo_data_doacao.dart';
import 'package:flutter_application_1/features/schedule/widgets/campo_medicamento.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../auth/services/auth_service.dart';
import 'services/openfda_service.dart';
import '../common/widgets/app_bottom_nav.dart';

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
      builder: (ctx) => DialogoResultado(
        apto: apto,
        motivo: motivo,
        onClose: () {
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
                const TituloQuestionario(),
                const SizedBox(height: 20),

                // Campo: Peso
                CampoPeso(ctrl: _ctrlPeso),
                const SizedBox(height: 16),

                // Perguntas de sim/não
                PerguntaSimNao(
                  pergunta: 'Já doou sangue antes?*',
                  valor: _jaDouSangue,
                  onChange: (v) => setState(() => _jaDouSangue = v),
                ),
                PerguntaSimNao(
                  pergunta:
                      'Teve febre ou sintomas de infecção nos últimos 30 dias?*',
                  valor: _teveFebre,
                  onChange: (v) => setState(() => _teveFebre = v),
                ),
                PerguntaSimNao(
                  pergunta: 'Tem Hepatite, HIV ou outra doença grave?*',
                  valor: _temHepatite,
                  onChange: (v) => setState(() => _temHepatite = v),
                ),
                PerguntaSimNao(
                  pergunta: 'Usa medicação contínua?*',
                  valor: _usaMedicacao,
                  onChange: (v) => setState(() => _usaMedicacao = v),
                ),

                // Campo de medicamento (condicional)
                if (_usaMedicacao == true)
                  CampoMedicamento(ctrl: _ctrlMedicamento),

                const SizedBox(height: 8),

                // Data da última doação
                CampoDataDoacao(ctrl: _ctrlData),
                const SizedBox(height: 28),

                // Botão verificar
                BotaoVerificar(
                  aVerificar: _aVerificar,
                  onClick: _verificarAptidao,
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

// ── Funções auxiliares ────────────────────────────────────────────────────────

/// Decoração padrão dos campos de texto do questionário.
InputDecoration decoracaoCampo(
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
