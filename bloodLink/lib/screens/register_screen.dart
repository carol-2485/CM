// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _idadeCtrl = TextEditingController();
  final _sangueCtrl = TextEditingController();
  final _historicoCtrl = TextEditingController();
  final _dataCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_nomeCtrl, _idadeCtrl, _sangueCtrl, _historicoCtrl, _dataCtrl, _emailCtrl, _passCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.register(
        nome: _nomeCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        idade: _idadeCtrl.text.trim(),
        tipoSanguineo: _sangueCtrl.text.trim(),
        historicoDencas: _historicoCtrl.text.trim(),
        dataUltimaDoacao: _dataCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_auth.getErrorMessage(e)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro: ${e.toString()}'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator ?? (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
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
                const SizedBox(height: 32),

                // Avatar
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.person_rounded, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 28),

                _field(_nomeCtrl, 'Nome*', Icons.person_outline),
                _field(_idadeCtrl, 'Idade*', Icons.cake_outlined, type: TextInputType.number),
                _field(_sangueCtrl, 'Tipo Sanguíneo*', Icons.water_drop_outlined),
                _field(_historicoCtrl, 'Histórico de doenças*', Icons.medical_information_outlined),

                // Data da última doação
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _dataCtrl,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 90)),
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
                      prefixIcon: const Icon(Icons.calendar_month_outlined, color: AppColors.primary, size: 20),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),

                _field(_emailCtrl, 'Email*', Icons.alternate_email,
                    type: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo obrigatório';
                      if (!v.contains('@')) return 'Email inválido';
                      return null;
                    }),

                // Password
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'Password*',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
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
                ),

                // Botão criar conta
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Criar conta',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 16),

                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
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
