// lib/screens/questionario_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../services/auth_service.dart';
import '../services/openfda_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/blood_drop.dart';

class QuestionarioScreen extends StatefulWidget {
  const QuestionarioScreen({super.key});
  @override
  State<QuestionarioScreen> createState() => _QuestionarioScreenState();
}

class _QuestionarioScreenState extends State<QuestionarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idadeCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _medicamentoCtrl = TextEditingController();
  final _dataCtrl = TextEditingController();

  bool? _jaDouSangue;
  bool? _teveFebre;
  bool? _temHepatite;
  bool? _usaMedicacao;
  bool _loading = false;

  final _auth = AuthService();
  final _fda = OpenFdaService();

  @override
  void dispose() {
    _idadeCtrl.dispose();
    _pesoCtrl.dispose();
    _medicamentoCtrl.dispose();
    _dataCtrl.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_jaDouSangue == null || _teveFebre == null ||
        _temHepatite == null || _usaMedicacao == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor responda a todas as perguntas.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _loading = true);

    bool apto = true;
    String? motivo;

    // Regra 1: Idade
    final idade = int.tryParse(_idadeCtrl.text) ?? 0;
    if (idade < 18 || idade > 65) {
      apto = false;
      motivo = 'A idade deve estar entre 18 e 65 anos.';
    }

    // Regra 2: Peso
    if (apto) {
      final peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 0;
      if (peso < 50) {
        apto = false;
        motivo = 'O peso mínimo para doação é 50 kg.';
      }
    }

    // Regra 3: Febre ou infecção recente
    if (apto && _teveFebre == true) {
      apto = false;
      motivo = 'Febre ou sintomas de infecção nos últimos 30 dias contraindica a doação.';
    }

    // Regra 4: Hepatite ou HIV
    if (apto && _temHepatite == true) {
      apto = false;
      motivo = 'Historial de Hepatite, HIV ou doença grave contraindica a doação.';
    }

    // Regra 5: Medicação — verifica lista local + OpenFDA API
    if (apto && _usaMedicacao == true) {
      final nomeMed = _medicamentoCtrl.text.trim();
      if (nomeMed.isEmpty) {
        // Se não indicou o medicamento, não pode ser validado
        apto = false;
        motivo = 'Indique o nome do medicamento para validar a sua aptidão.';
      } else {
        final resultado = await _fda.verificarMedicamento(nomeMed);
        if (resultado['contraindica'] == true) {
          apto = false;
          motivo = resultado['mensagem'] as String;
        }
      }
    }

    setState(() => _loading = false);
    if (!mounted) return;

    // Guarda o resultado no Firestore
    await _auth.updateEligibility(apto);
    if (!mounted) return;

    _showResultado(apto, motivo);
  }

  void _showResultado(bool apto, String? motivo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: apto ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                apto ? Icons.check_rounded : Icons.close_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              apto ? 'Está apto para doar sangue!' : 'Não está apto de momento.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (motivo != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: apto
                      ? AppColors.success.withOpacity(0.08)
                      : AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  motivo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: apto ? AppColors.success : AppColors.error,
                    height: 1.4,
                  ),
                ),
              ),
            ],
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
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              },
              child: Text(
                apto ? 'Ver centros de doação' : 'Voltar ao início',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _yesNo(String question, bool? value, void Function(bool) onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Radio<bool>(
                  value: true, groupValue: value, onChanged: (v) => onChange(v!)),
              const Text('Sim', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 24),
              Radio<bool>(
                  value: false, groupValue: value, onChanged: (v) => onChange(v!)),
              const Text('Não', style: TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BloodDrop(size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Questionário de\nAptidão para Doação',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Idade
                TextFormField(
                  controller: _idadeCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Idade*',
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
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo obrigatório';
                    final i = int.tryParse(v);
                    if (i == null || i < 18 || i > 65)
                      return 'Deve ter entre 18 e 65 anos';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Peso
                TextFormField(
                  controller: _pesoCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Peso (Kg)*',
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
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo obrigatório';
                    final p = double.tryParse(v.replaceAll(',', '.'));
                    if (p == null || p < 50) return 'Peso mínimo é 50 kg';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _yesNo('Já doou sangue antes?*', _jaDouSangue,
                    (v) => setState(() => _jaDouSangue = v)),
                _yesNo(
                    'Teve febre ou sintomas de infecção nos últimos 30 dias?*',
                    _teveFebre,
                    (v) => setState(() => _teveFebre = v)),
                _yesNo('Tem Hepatite, HIV ou outra doença grave?*',
                    _temHepatite,
                    (v) => setState(() => _temHepatite = v)),
                _yesNo('Usa medicação contínua?*', _usaMedicacao,
                    (v) => setState(() => _usaMedicacao = v)),

                // Campo medicamento
                if (_usaMedicacao == true) ...[
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _medicamentoCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nome do medicamento *',
                      prefixIcon: const Icon(Icons.medication_outlined,
                          color: AppColors.textMuted),
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
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5)),
                    ),
                    validator: (v) => (_usaMedicacao == true &&
                            (v == null || v.isEmpty))
                        ? 'Indique o nome do medicamento'
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: AppColors.primary),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'A app verifica o medicamento contra a lista do IPST e a OpenFDA API.',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 8),

                // Data da última doação
                TextFormField(
                  controller: _dataCtrl,
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.now().subtract(const Duration(days: 90)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      _dataCtrl.text =
                          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Data da última doação',
                    suffixIcon: const Icon(Icons.calendar_month_outlined,
                        color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                  ),
                ),

                const SizedBox(height: 28),

                // Botão verificar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verificar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Verificar Aptidão',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
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
