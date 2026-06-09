// lib/features/painel/widgets/header_painel.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../common/services/notificacao_service.dart';
import 'contador_painel.dart';

class HeaderPainel extends StatelessWidget {
  final String nome;
  final String? fotoUrl;
  final int totalDoacoes;
  final double sangueDoado;
  final int pessoasSalvas;
  final VoidCallback onNotificacoesTap;
  final VoidCallback onVoltar;

  const HeaderPainel({
    super.key,
    required this.nome,
    required this.fotoUrl,
    required this.totalDoacoes,
    required this.sangueDoado,
    required this.pessoasSalvas,
    required this.onNotificacoesTap,
    required this.onVoltar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BarraTopo(onVoltar: onVoltar, onNotificacoes: onNotificacoesTap),
              const SizedBox(height: 14),
              _IdentidadeDoador(nome: nome, fotoUrl: fotoUrl),
              const SizedBox(height: 18),
              Row(children: [
                ContadorPainel(valor: '$totalDoacoes', rotulo: 'Doações\nrealizadas'),
                const SizedBox(width: 10),
                ContadorPainel(valor: '${sangueDoado.toStringAsFixed(1)}L', rotulo: 'Sangue\ndoado'),
                const SizedBox(width: 10),
                ContadorPainel(valor: '$pessoasSalvas', rotulo: 'Vidas\nsalvas'),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarraTopo extends StatelessWidget {
  final VoidCallback onVoltar;
  final VoidCallback onNotificacoes;
  const _BarraTopo({required this.onVoltar, required this.onNotificacoes});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      GestureDetector(
        onTap: onVoltar,
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
      ),
      const Spacer(),
      StreamBuilder<int>(
        stream: NotificacaoService.contagemNaoLidasStream(),
        builder: (context, snap) {
          final naoLidas = (snap.hasData && snap.data! > 0) ? snap.data! : 0;
          return GestureDetector(
            onTap: onNotificacoes,
            child: Stack(clipBehavior: Clip.none, children: [
              const Icon(Icons.notifications_outlined, color: Colors.white70, size: 24),
              if (naoLidas > 0)
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Text('$naoLidas',
                        style: const TextStyle(fontSize: 8, color: AppColors.primary, fontWeight: FontWeight.w800)),
                  ),
                ),
            ]),
          );
        },
      ),
    ]);
  }
}

class _IdentidadeDoador extends StatelessWidget {
  final String nome;
  final String? fotoUrl;
  const _IdentidadeDoador({required this.nome, this.fotoUrl});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
        ),
        child: fotoUrl != null && fotoUrl!.isNotEmpty
            ? ClipOval(child: Image.network(fotoUrl!, fit: BoxFit.cover))
            : const Icon(Icons.person_rounded, color: Colors.white, size: 30),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('PAINEL DO DOADOR',
            style: TextStyle(fontSize: 10, color: Colors.white60,
                fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        const SizedBox(height: 2),
        Text(nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const Text('Doador BloodLink', style: TextStyle(fontSize: 12, color: Colors.white60)),
      ]),
    ]);
  }
}
