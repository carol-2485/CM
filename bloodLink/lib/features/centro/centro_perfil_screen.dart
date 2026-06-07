// lib/features/centro/centro_perfil_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../auth/services/auth_service.dart';
import 'widgets/app_bottom_nav_centro.dart';
import 'widgets/cabecalho_perfil_centro.dart';
import 'widgets/cartao_info_centro.dart';
import 'widgets/botao_terminar_sessao_centro.dart';

class CentroPerfilScreen extends StatefulWidget {
  const CentroPerfilScreen({super.key});
  @override
  State<CentroPerfilScreen> createState() => _CentroPerfilScreenState();
}

class _CentroPerfilScreenState extends State<CentroPerfilScreen> {
  final _auth = AuthService();
  Map<String, dynamic>? _dados;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarCentro();
  }

  Future<void> _carregarCentro() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('centros').doc(uid).get();

    if (!doc.exists) {
      final q = await FirebaseFirestore.instance
          .collection('centros').where('uid', isEqualTo: uid).limit(1).get();
      if (q.docs.isNotEmpty) doc = q.docs.first;
    }

    if (mounted) {
      setState(() {
        _dados = doc.exists ? doc.data() as Map<String, dynamic>? : {};
        _carregando = false;
      });
    }
  }

  Future<void> _terminarSessao() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final nome = _dados?['nome'] ?? 'Centro de Saúde';
    final email = FirebaseAuth.instance.currentUser?.email ?? '—';
    final morada = _dados?['morada'] ?? '—';
    final telefone = _dados?['telefone'] ?? '—';
    final horario = _dados?['horario'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CabecalhoPerfilCentro(nome: nome, email: email),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SecaoCabecalho(
                    titulo: 'Informações do Centro',
                    icone: Icons.local_hospital_outlined),
                const SizedBox(height: 10),
                CartaoInfoCentro(linhas: [
                  LinhaInfoCentro(rotulo: 'Morada', valor: morada,
                      icone: Icons.location_on_outlined, corIcone: const Color(0xFF0EA5E9)),
                  LinhaInfoCentro(rotulo: 'Telefone', valor: telefone,
                      icone: Icons.phone_outlined, corIcone: const Color(0xFF22C55E)),
                  LinhaInfoCentro(rotulo: 'Email', valor: email,
                      icone: Icons.email_outlined, corIcone: const Color(0xFF8B5CF6)),
                ]),
                const SizedBox(height: 20),

                // ── Horário de funcionamento ────────────────────────────
                _SecaoCabecalho(
                    titulo: 'Horário de Funcionamento',
                    icone: Icons.schedule_outlined),
                const SizedBox(height: 10),
                _HorarioFuncionamento(horario: horario),
                const SizedBox(height: 28),
                BotaoTerminarSessaoCentro(onTap: _terminarSessao),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavCentro(currentIndex: 3),
    );
  }
}

class _SecaoCabecalho extends StatelessWidget {
  final String titulo;
  final IconData icone;
  const _SecaoCabecalho({required this.titulo, required this.icone});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icone, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(titulo, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
    ]);
  }
}

class _HorarioFuncionamento extends StatelessWidget {
  final Map<String, dynamic>? horario;
  const _HorarioFuncionamento({this.horario});

  // Horário padrão se não houver dados
  static const _diasOrdem = [
    'segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado', 'domingo'
  ];
  static const _diasLabels = {
    'segunda': 'Segunda',
    'terca': 'Terça',
    'quarta': 'Quarta',
    'quinta': 'Quinta',
    'sexta': 'Sexta',
    'sabado': 'Sábado',
    'domingo': 'Domingo',
  };
  static const _horarioPadrao = {
    'segunda': '08:00 - 18:00',
    'terca': '08:00 - 18:00',
    'quarta': '08:00 - 18:00',
    'quinta': '08:00 - 18:00',
    'sexta': '08:00 - 18:00',
    'sabado': '09:00 - 13:00',
    'domingo': 'Encerrado',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(_diasOrdem.length, (i) {
          final chave = _diasOrdem[i];
          final label = _diasLabels[chave] ?? chave;
          final valor = horario?[chave] as String? ?? _horarioPadrao[chave] ?? '—';
          final encerrado = valor == 'Encerrado';
          final isLast = i == _diasOrdem.length - 1;

          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(valor,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: encerrado ? AppColors.error : AppColors.accent,
                    )),
              ]),
            ),
            if (!isLast)
              Divider(height: 1, color: AppColors.border.withOpacity(0.5), indent: 16, endIndent: 16),
          ]);
        }),
      ),
    );
  }
}
