import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../auth/services/auth_service.dart';
import '../common/widgets/action_tile.dart';
import '../common/widgets/highlight_card.dart';
import '../common/widgets/profile_header.dart';
import '../common/widgets/section_label.dart';
import 'widgets/app_bottom_nav_centro.dart';

class CentroHomeScreen extends StatefulWidget {
  const CentroHomeScreen({super.key});

  @override
  State<CentroHomeScreen> createState() => _CentroHomeScreenState();
}

class _CentroHomeScreenState extends State<CentroHomeScreen> {
  final _auth = AuthService();
  Map<String, dynamic>? _centroData;
  int _consultasHoje = 0;
  int _pedidosPendentes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // dados do centro
    final centroDoc = await FirebaseFirestore.instance
        .collection('centros')
        .doc(uid)
        .get();

    // contar consultas de hoje
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    /* final consultas = await FirebaseFirestore.instance
        .collection('centros')
        .doc(uid)
        .collection('vagas')
        .where('data', isGreaterThanOrEqualTo: inicioDia)
        .where('data', isLessThan: fimDia)
        .where('estado', isEqualTo: 'aceite')
        .count()
        .get();

    // contar pedidos pendentes
    final pedidos = await FirebaseFirestore.instance
        .collection('centros')
        .doc(uid)
        .collection('vagas')
        .where('estado', isEqualTo: 'confirmado')
        .count()
        .get(); */

    if (mounted) {
      setState(() {
        _centroData = centroDoc.data();
        _consultasHoje = /* consultas.count ?? */ 0;
        _pedidosPendentes = /* pedidos.count ?? */ 0;
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutesUser.login);
  }

  @override
  Widget build(BuildContext context) {
    final nome = _centroData?['nome'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    ProfileHeader(
                      nome: nome,
                      subtitle: 'Aqui está o seu resumo.',
                      avatarIcon: Icons.local_hospital,
                      onLogout: _logout,
                    ),
                    const SizedBox(height: 24),
                    HighlightCard(
                      icon: Icons.today,
                      title: 'Consultas de Hoje',
                      subtitle: '$_consultasHoje consultas agendadas',
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                    const SectionLabel('O QUE QUER FAZER?'),
                    const SizedBox(height: 12),
                    ActionTile(
                      icon: Icons.event_available,
                      iconBg: AppColors.primary,
                      title: 'Gerir Vagas',
                      subtitle: 'Criar e editar slots disponíveis',
                      onTap: () {},
                    ),
                    ActionTile(
                      icon: Icons.pending_actions,
                      title: 'Pedidos Pendentes',
                      subtitle: '$_pedidosPendentes a aguardar resposta',
                      onTap: () {},
                    ),
                    ActionTile(
                      icon: Icons.check_circle_outline,
                      title: 'Consultas Confirmadas',
                      subtitle: 'Ver próximas consultas',
                      onTap: () {},
                    ),
                    ActionTile(
                      icon: Icons.history,
                      title: 'Histórico',
                      subtitle: 'Consultas anteriores',
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNavCentro(currentIndex: 0),
    );
  }
}