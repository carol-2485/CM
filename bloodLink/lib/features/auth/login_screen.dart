// lib/features/auth/login_screen.dart
//
// Ecrã de autenticação da aplicação BloodLink.
// Suporta utilizadores doadores e centros de saúde — após login
// detecta automaticamente o tipo de conta e redireciona para o ecrã correcto.
// Inclui recuperação de palavra-passe via modal de fundo.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/features/common/widgets/blood_drop.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import 'services/auth_service.dart';

/// Ecrã de login da aplicação.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── Controladores ─────────────────────────────────────────────────────────
  final _chaveFormulario = GlobalKey<FormState>();
  final _ctrlEmail = TextEditingController();
  final _ctrlPassword = TextEditingController();

  // ── Serviços ──────────────────────────────────────────────────────────────
  final _servAutenticacao = AuthService();

  // ── Estado ────────────────────────────────────────────────────────────────
  bool _lembrar = false;
  bool _esconderPassword = true;
  bool _aAutenticar = false;

  @override
  void dispose() {
    _ctrlEmail.dispose();
    _ctrlPassword.dispose();
    super.dispose();
  }

  // ── Lógica de negócio ─────────────────────────────────────────────────────

  /// Autentica o utilizador e redireciona conforme o tipo de conta.
  Future<void> _entrar() async {
    if (!_chaveFormulario.currentState!.validate()) return;
    setState(() => _aAutenticar = true);

    try {
      final credencial = await _servAutenticacao.login(
        _ctrlEmail.text,
        _ctrlPassword.text,
      );
      if (!mounted) return;

      // Determina se é conta de centro de saúde
      final eCentro = await _verificarSeCentro(credencial.user!.uid);
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        eCentro ? AppRoutesCentro.home : AppRoutesUser.home,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _mostrarErro(_servAutenticacao.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _aAutenticar = false);
    }
  }

  /// Verifica no Firestore se o UID pertence a um centro de saúde.
  Future<bool> _verificarSeCentro(String uid) async {
    // Tenta pelo ID do documento
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('centros')
        .doc(uid)
        .get();
    if (doc.exists) return true;

    // Fallback: campo 'uid' no documento
    final query = await FirebaseFirestore.instance
        .collection('centros')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Apresenta uma SnackBar de erro.
  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensagem),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  /// Abre o modal de recuperação de palavra-passe.
  void _abrirRecuperacao() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModalRecuperacao(
        servAutenticacao: _servAutenticacao,
        onSucesso: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Email de recuperação enviado!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ));
        },
      ),
    );
  }

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
                const SizedBox(height: 60),

                // Logo e tagline
                const _CabecalhoLogin(),
                const SizedBox(height: 36),

                // Campo de email
                _CampoLogin(
                  ctrl: _ctrlEmail,
                  dica: 'Nome de utilizador',
                  icone: Icons.person_outline,
                  teclado: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                // Campo de password
                _CampoPassword(
                  ctrl: _ctrlPassword,
                  esconder: _esconderPassword,
                  onAlternarVisibilidade: () =>
                      setState(() => _esconderPassword = !_esconderPassword),
                ),
                const SizedBox(height: 8),

                // Linha "Lembrar-me" + "Esqueceu-se?"
                _LinhaOpcoes(
                  lembrar: _lembrar,
                  onLembrarAlterado: (v) =>
                      setState(() => _lembrar = v ?? false),
                  onEsqueceu: _abrirRecuperacao,
                ),
                const SizedBox(height: 16),

                // Botão entrar
                _BotaoEntrar(
                  aAutenticar: _aAutenticar,
                  aoPremir: _entrar,
                ),
                const SizedBox(height: 24),

                // Link de registo
                _LinkRegisto(
                  aoPremir: () =>
                      Navigator.pushNamed(context, AppRoutesUser.register),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

/// Cabeçalho com logo e tagline da aplicação.
class _CabecalhoLogin extends StatelessWidget {
  const _CabecalhoLogin();

  @override
  Widget build(BuildContext context) {
    return Column(children: const [
      BloodDrop(size: 90),
      SizedBox(height: 28),
      Text(
        'Doe sangue,\nsalve vidas',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.accent,
          height: 1.2,
        ),
      ),
    ]);
  }
}

/// Campo de texto de login com estilo pill.
class _CampoLogin extends StatelessWidget {
  final TextEditingController ctrl;
  final String dica;
  final IconData icone;
  final TextInputType teclado;

  const _CampoLogin({
    required this.ctrl,
    required this.dica,
    required this.icone,
    this.teclado = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: teclado,
      decoration: _decoracaoPill(dica, icone),
      validator: (v) =>
          v == null || v.isEmpty ? 'Campo obrigatório' : null,
    );
  }
}

/// Campo de password com toggle de visibilidade.
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
    return TextFormField(
      controller: ctrl,
      obscureText: esconder,
      decoration: _decoracaoPill('Palavra-passe', Icons.lock_outline).copyWith(
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
    );
  }
}

/// Linha com checkbox "Lembrar-me" e link "Esqueceu-se da palavra-passe?".
class _LinhaOpcoes extends StatelessWidget {
  final bool lembrar;
  final void Function(bool?) onLembrarAlterado;
  final VoidCallback onEsqueceu;

  const _LinhaOpcoes({
    required this.lembrar,
    required this.onLembrarAlterado,
    required this.onEsqueceu,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Checkbox(
        value: lembrar,
        onChanged: onLembrarAlterado,
        activeColor: AppColors.primary,
      ),
      const Text('Lembrar-me', style: TextStyle(fontSize: 13)),
      const Spacer(),
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onEsqueceu,
          child: const Text(
            'Esqueceu-se da palavra-passe?',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ),
      ),
    ]);
  }
}

/// Botão principal de autenticação.
class _BotaoEntrar extends StatelessWidget {
  final bool aAutenticar;
  final VoidCallback aoPremir;

  const _BotaoEntrar({required this.aAutenticar, required this.aoPremir});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: aAutenticar ? null : aoPremir,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
        ),
        child: aAutenticar
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Entrar',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
      ),
    );
  }
}

/// Link para navegar para o ecrã de registo.
class _LinkRegisto extends StatelessWidget {
  final VoidCallback aoPremir;
  const _LinkRegisto({required this.aoPremir});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text(
        'Ainda não tem conta? ',
        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
      ),
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: aoPremir,
          child: const Text(
            'Registe-se',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ),
      ),
    ]);
  }
}

// ── Modal de recuperação de palavra-passe ─────────────────────────────────────

/// Modal de fundo para o utilizador introduzir o email de recuperação.
class _ModalRecuperacao extends StatelessWidget {
  final AuthService servAutenticacao;
  final VoidCallback onSucesso;

  const _ModalRecuperacao({
    required this.servAutenticacao,
    required this.onSucesso,
  });

  @override
  Widget build(BuildContext context) {
    final ctrlEmail = TextEditingController();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de arraste
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Recuperar palavra-passe',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Introduza o seu email para receber um link de recuperação.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            // Campo de email
            TextFormField(
              controller: ctrlEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botão de envio
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await servAutenticacao.sendPasswordReset(ctrlEmail.text);
                  onSucesso();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Enviar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Utilitários ───────────────────────────────────────────────────────────────

/// Decoração padrão com bordas em pill para campos de texto do login.
InputDecoration _decoracaoPill(String dica, IconData icone) {
  return InputDecoration(
    hintText: dica,
    prefixIcon: Icon(icone, color: AppColors.textMuted),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
  );
}
