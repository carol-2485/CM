// lib/features/centro/centro_home_screen.dart
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
import '../chat_centro/chat_lista_screen.dart';
import 'widgets/app_bottom_nav_centro.dart';

class CentroHomeScreen extends StatefulWidget {
  const CentroHomeScreen({super.key});
  @override
  State<CentroHomeScreen> createState() => _CentroHomeScreenState();
}

class _CentroHomeScreenState extends State<CentroHomeScreen> {
  final _auth = AuthService();
  Map<String, dynamic>? _centroData;
  String? _centroDocId;
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

    // Resolve o documento do centro
    DocumentSnapshot centroDoc = await FirebaseFirestore.instance
        .collection('centros').doc(uid).get();

    if (!centroDoc.exists) {
      final q = await FirebaseFirestore.instance
          .collection('centros').where('uid', isEqualTo: uid).limit(1).get();
      if (q.docs.isNotEmpty) centroDoc = q.docs.first;
    }

    final centroId = centroDoc.id;

    // Hoje em dataKey
    final hoje = DateTime.now();
    final hojeKey = '${hoje.year}-${hoje.month.toString().padLeft(2,'0')}-${hoje.day.toString().padLeft(2,'0')}';

    // Consultas confirmadas para hoje
    final consultasSnap = await FirebaseFirestore.instance
        .collection('vagas')
        .where('centroId', isEqualTo: centroId)
        .where('dataKey', isEqualTo: hojeKey)
        .where('estado', isEqualTo: 'confirmado')
        .get();

    // Pedidos pendentes
    final pendentesSnap = await FirebaseFirestore.instance
        .collection('vagas')
        .where('centroId', isEqualTo: centroId)
        .where('estado', isEqualTo: 'pendente')
        .get();

    if (mounted) {
      setState(() {
        _centroData = centroDoc.data() as Map<String, dynamic>?;
        _centroDocId = centroId;
        _consultasHoje = consultasSnap.docs.length;
        _pedidosPendentes = pendentesSnap.docs.length;
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    ProfileHeader(
                      nome: nome,
                      subtitle: 'Bom dia! Aqui está o seu resumo.',
                      avatarIcon: Icons.local_hospital,
                      onLogout: _logout,
                    ),
                    const SizedBox(height: 24),
                    HighlightCard(
                      icon: Icons.today,
                      title: 'Consultas de Hoje',
                      subtitle: '$_consultasHoje consultas agendadas para hoje',
                      onTap: () => Navigator.pushNamed(context, AppRoutesCentro.pedidos),
                    ),
                    const SizedBox(height: 24),
                    const SectionLabel('O QUE QUER FAZER?'),
                    const SizedBox(height: 12),
                    ActionTile(
                      icon: Icons.event_available,
                      iconBg: AppColors.primary,
                      title: 'Gerir Vagas',
                      subtitle: 'Criar e editar slots disponíveis',
                      onTap: () => Navigator.pushNamed(context, AppRoutesCentro.gerirVagas),
                    ),
                    ActionTile(
                      icon: Icons.pending_actions,
                      title: 'Pedidos Pendentes',
                      subtitle: _pedidosPendentes > 0
                          ? '$_pedidosPendentes a aguardar resposta'
                          : 'Sem pedidos pendentes',
                      badge: _pedidosPendentes > 0 ? '$_pedidosPendentes' : null,
                      onTap: () => Navigator.pushNamed(context, AppRoutesCentro.pedidos),
                    ),
                    ActionTile(
                      icon: Icons.chat_bubble_outline,
                      title: 'Mensagens',
                      subtitle: 'Chat com doadores',
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ChatListaCentroScreen())),
                    ),
                    ActionTile(
                      icon: Icons.check_circle_outline,
                      title: 'Consultas Confirmadas',
                      subtitle: 'Ver próximas consultas',
                      onTap: () => Navigator.pushNamed(context, AppRoutesCentro.pedidos),
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
