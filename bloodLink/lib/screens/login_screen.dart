// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../services/auth_service.dart';
import '../widgets/blood_drop.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _lembrar = false;
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.login(_emailCtrl.text, _passCtrl.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_auth.getErrorMessage(e)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Recuperar palavra-passe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent)),
              const SizedBox(height: 8),
              const Text('Introduza o seu email para receber um link de recuperação.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _auth.sendPasswordReset(emailCtrl.text);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Email de recuperação enviado!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Enviar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
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
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 60),
                const BloodDrop(size: 90),
                const SizedBox(height: 28),
                const Text(
                  'Doe sangue,\nsalve vidas',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.accent, height: 1.2),
                ),
                const SizedBox(height: 36),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Nome de utilizador',
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 12),

                // Password
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Palavra-passe',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textMuted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 8),

                // Lembrar-me
                Row(
                  children: [
                    Checkbox(value: _lembrar, onChanged: (v) => setState(() => _lembrar = v ?? false)),
                    const Text('Lembrar-me', style: TextStyle(fontSize: 13)),
                    const Spacer(),
                    // "Esqueceu-se" com efeito hover
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _showForgotPassword,
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
                  ],
                ),

                const SizedBox(height: 16),

                // Botão entrar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Entrar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 24),

                // Registe-se com efeito hover
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Ainda não tem conta? ',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.register),
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
                  ],
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
