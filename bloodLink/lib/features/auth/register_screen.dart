// lib/features/auth/register_screen.dart
//
// Ecrã de registo de novo utilizador (doador).
// Recolhe os dados pessoais e de saúde necessários para criar a conta.
// Utiliza um dropdown para o histórico de doenças, evitando texto livre ambíguo.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import 'services/auth_service.dart';

/// Ecrã de registo de conta de doador.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ── Controladores de formulário ───────────────────────────────────────────
  final _chaveFormulario = GlobalKey<FormState>();
  final _ctrlNome = TextEditingController();
  final _ctrlIdade = TextEditingController();
  final _ctrlSangue = TextEditingController();
  final _ctrlHistoricoTexto = TextEditingController();
  final _ctrlData = TextEditingController();
  final _ctrlEmail = TextEditingController();
  final _ctrlPassword = TextEditingController();

  // ── Serviços ──────────────────────────────────────────────────────────────
  final _servAutenticacao = AuthService();

  // ── Estado ────────────────────────────────────────────────────────────────
  bool _esconderPassword = true;
  bool _aRegistar = false;
  String? _temHistorico; // 'sim' | 'nao'
  String _textoHistorico = '';

  @override
  void dispose() {
    _ctrlNome.dispose();
    _ctrlIdade.dispose();
    _ctrlSangue.dispose();
    _ctrlHistoricoTexto.dispose();
    _ctrlData.dispose();
    _ctrlEmail.dispose();
    _ctrlPassword.dispose();
    super.dispose();
  }

  // ── Lógica de negócio ─────────────────────────────────────────────────────

  /// Devolve o valor final do histórico de doenças para guardar no Firestore.
  String _historicoFinal() {
    if (_temHistorico == 'nao') return 'Nenhum';
    if (_temHistorico == 'sim') {
      return _textoHistorico.trim().isEmpty ? 'Sim' : _textoHistorico.trim();
    }
    return '';
  }

  /// Valida o formulário e cria a conta no Firebase.
  Future<void> _registar() async {
    if (!_chaveFormulario.currentState!.validate()) return;
    setState(() => _aRegistar = true);
    try {
      await _servAutenticacao.register(
        nome: _ctrlNome.text.trim(),
        email: _ctrlEmail.text.trim(),
        password: _ctrlPassword.text,
        idade: _ctrlIdade.text.trim(),
        tipoSanguineo: _ctrlSangue.text.trim(),
        historicoDencas: _historicoFinal(),
        dataUltimaDoacao: _ctrlData.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutesUser.home);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _mostrarErro(_servAutenticacao.getErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      _mostrarErro('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _aRegistar = false);
    }
  }

  /// Apresenta uma SnackBar com a mensagem de erro.
  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensagem),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Interface ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _chaveFormulario,
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Avatar decorativo
                const _AvatarRegisto(),
                const SizedBox(height: 28),

                // Campos básicos
                _CampoTexto(
                  ctrl: _ctrlNome,
                  dica: 'Nome*',
                  icone: Icons.person_outline,
                ),
                _CampoTexto(
                  ctrl: _ctrlIdade,
                  dica: 'Idade*',
                  icone: Icons.cake_outlined,
                  teclado: TextInputType.number,
                ),
                _CampoTexto(
                  ctrl: _ctrlSangue,
                  dica: 'Tipo Sanguíneo*',
                  icone: Icons.water_drop_outlined,
                ),

                // Dropdown: histórico de doenças
                _CampoHistorico(
                  valorSelecionado: _temHistorico,
                  onAlterado: (v) => setState(() {
                    _temHistorico = v;
                    if (v == 'nao') _textoHistorico = '';
                  }),
                  mostrarCampoDescricao: _temHistorico == 'sim',
                  onDescricaoAlterada: (v) => _textoHistorico = v,
                  ctrlDescricao: _ctrlHistoricoTexto,
                ),

                // Selector de data da última doação
                _CampoData(ctrl: _ctrlData),

                // Email
                _CampoTexto(
                  ctrl: _ctrlEmail,
                  dica: 'Email*',
                  icone: Icons.alternate_email,
                  teclado: TextInputType.emailAddress,
                  validador: (v) {
                    if (v == null || v.isEmpty) return 'Campo obrigatório';
                    if (!v.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),

                // Password
                _CampoPassword(
                  ctrl: _ctrlPassword,
                  esconder: _esconderPassword,
                  onAlternarVisibilidade: () =>
                      setState(() => _esconderPassword = !_esconderPassword),
                ),

                // Botão de criar conta
                _BotaoCriarConta(
                  aRegistar: _aRegistar,
                  aoPremir: _registar,
                ),
                const SizedBox(height: 16),

                // Link para login
                _LinkLogin(aoPremir: () => Navigator.pop(context)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets internos ─────────────────────────────────────────────────────────

/// Avatar decorativo no topo do ecrã de registo.
class _AvatarRegisto extends StatelessWidget {
  const _AvatarRegisto();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.person_rounded, size: 50, color: Colors.white),
    );
  }
}

/// Campo de texto genérico com estilo padrão da aplicação.
class _CampoTexto extends StatelessWidget {
  final TextEditingController ctrl;
  final String dica;
  final IconData icone;
  final TextInputType teclado;
  final String? Function(String?)? validador;

  const _CampoTexto({
    required this.ctrl,
    required this.dica,
    required this.icone,
    this.teclado = TextInputType.text,
    this.validador,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: teclado,
        decoration: _decoracao(dica, icone),
        validator: validador ??
            (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
      ),
    );
  }
}

/// Dropdown para o histórico de doenças, com campo de texto condicional.
class _CampoHistorico extends StatelessWidget {
  final String? valorSelecionado;
  final void Function(String?) onAlterado;
  final bool mostrarCampoDescricao;
  final void Function(String) onDescricaoAlterada;
  final TextEditingController ctrlDescricao;

  const _CampoHistorico({
    required this.valorSelecionado,
    required this.onAlterado,
    required this.mostrarCampoDescricao,
    required this.onDescricaoAlterada,
    required this.ctrlDescricao,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown principal
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(30),
            ),
            child: DropdownButtonFormField<String>(
              value: valorSelecionado,
              decoration: _decoracao(
                  'Histórico de doenças*',
                  Icons.medical_information_outlined),
              items: const [
                DropdownMenuItem(value: 'nao', child: Text('Não')),
                DropdownMenuItem(
                    value: 'sim', child: Text('Sim, qual?')),
              ],
              onChanged: onAlterado,
              validator: (v) =>
                  v == null ? 'Selecione uma opção' : null,
            ),
          ),

          // Campo de descrição (apenas quando "Sim")
          if (mostrarCampoDescricao) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: ctrlDescricao,
              onChanged: onDescricaoAlterada,
              decoration: _decoracaoArredondada(
                  'Descreva brevemente*',
                  Icons.edit_note_rounded),
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Descreva o histórico'
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

/// Selector de data da última doação com DatePicker.
class _CampoData extends StatelessWidget {
  final TextEditingController ctrl;
  const _CampoData({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        readOnly: true,
        onTap: () async {
          final escolhida = await showDatePicker(
            context: context,
            initialDate:
                DateTime.now().subtract(const Duration(days: 90)),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (escolhida != null) {
            ctrl.text =
                '${escolhida.day.toString().padLeft(2, '0')}/${escolhida.month.toString().padLeft(2, '0')}/${escolhida.year}';
          }
        },
        decoration: _decoracao(
            'Data da última doação',
            Icons.calendar_month_outlined),
      ),
    );
  }
}

/// Campo de password com botão de visibilidade.
class _CampoPassword extends StatelessWidget {
  final TextEditingController ctrl;
  final bool esconder;
  final VoidCallback onAlternarVisibilidade;

  const _CampoPassword({
    required this.ctrl,
    required this.esconder,
    required this.onAlternarVisibilidade,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TextFormField(
        controller: ctrl,
        obscureText: esconder,
        decoration: _decoracao(
          'Password*',
          Icons.lock_outline,
        ).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              esconder
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textMuted,
            ),
            onPressed: onAlternarVisibilidade,
          ),
        ),
        validator: (v) =>
            v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
      ),
    );
  }
}

/// Botão de criação de conta com indicador de carregamento.
class _BotaoCriarConta extends StatelessWidget {
  final bool aRegistar;
  final VoidCallback aoPremir;

  const _BotaoCriarConta({
    required this.aRegistar,
    required this.aoPremir,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: aRegistar ? null : aoPremir,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: aRegistar
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Criar conta',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
      ),
    );
  }
}

/// Link para navegar para o ecrã de login.
class _LinkLogin extends StatelessWidget {
  final VoidCallback aoPremir;
  const _LinkLogin({required this.aoPremir});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: aoPremir,
        child: const Text(
          'Já tem conta? Entrar',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── Funções auxiliares de decoração ──────────────────────────────────────────

/// Decoração padrão dos campos de texto com bordas arredondadas (pill).
InputDecoration _decoracao(String dica, IconData icone) {
  return InputDecoration(
    hintText: dica,
    prefixIcon: Icon(icone, color: AppColors.primary, size: 20),
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
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  );
}

/// Decoração com bordas menos arredondadas (para campos secundários).
InputDecoration _decoracaoArredondada(String dica, IconData icone) {
  return InputDecoration(
    hintText: dica,
    prefixIcon: Icon(icone, color: AppColors.primary, size: 20),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5)),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  );
}
