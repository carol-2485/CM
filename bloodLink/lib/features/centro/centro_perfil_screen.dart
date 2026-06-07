// lib/features/centro/centro_perfil_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../auth/services/auth_service.dart';
import '../common/widgets/blood_drop.dart';
import 'widgets/app_bottom_nav_centro.dart';

class CentroPerfilScreen extends StatefulWidget {
  const CentroPerfilScreen({super.key});
  @override
  State<CentroPerfilScreen> createState() => _CentroPerfilScreenState();
}

class _CentroPerfilScreenState extends State<CentroPerfilScreen> {
  final _auth = AuthService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCentro();
  }

  Future<void> _loadCentro() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Tenta pelo ID do documento
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('centros').doc(uid).get();

    // Se não encontrar, procura pelo campo uid
    if (!doc.exists) {
      final q = await FirebaseFirestore.instance
          .collection('centros').where('uid', isEqualTo: uid).limit(1).get();
      if (q.docs.isNotEmpty) doc = q.docs.first;
    }

    if (mounted) {
      setState(() {
        _data = doc.exists ? doc.data() as Map<String, dynamic>? : {};
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header vermelho
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Column(
                        children: [
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: const Icon(Icons.local_hospital_rounded,
                                color: Colors.white, size: 38),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _data?['nome'] ?? 'Centro de Saúde',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            FirebaseAuth.instance.currentUser?.email ?? '',
                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('INFORMAÇÕES DO CENTRO', style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: AppColors.textMuted, letterSpacing: 0.5)),
                          const SizedBox(height: 12),

                          _infoCard(Icons.location_on_outlined, 'Morada',
                              _data?['morada'] ?? '—'),
                          _infoCard(Icons.phone_outlined, 'Telefone',
                              _data?['telefone'] ?? '—'),
                          _infoCard(Icons.email_outlined, 'Email',
                              FirebaseAuth.instance.currentUser?.email ?? '—'),
                          _infoCard(Icons.pin_drop_outlined, 'Coordenadas',
                              '${_data?['latitude'] ?? '—'}, ${_data?['longitude'] ?? '—'}'),

                          const SizedBox(height: 24),

                          // Botão logout
                          OutlinedButton(
                            onPressed: _logout,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Terminar sessão',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNavCentro(currentIndex: 3),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
              fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent)),
        ])),
      ]),
    );
  }
}
