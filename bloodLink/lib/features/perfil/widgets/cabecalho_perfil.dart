// lib/features/perfil/widgets/cabecalho_perfil.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class CabecalhoPerfil extends StatelessWidget {
  final String nome;
  final String email;
  final int totalDoacoes;
  final String tipoSanguineo;
  final String idade;
  final VoidCallback onVoltar;

  const CabecalhoPerfil({
    super.key,
    required this.nome,
    required this.email,
    required this.totalDoacoes,
    required this.tipoSanguineo,
    required this.idade,
    required this.onVoltar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            children: [
              _BarraTopo(onVoltar: onVoltar),
              const SizedBox(height: 24),
              const _AvatarEstatico(),
              const SizedBox(height: 12),
              Text(nome,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 2),
              Text(email,
                  style: const TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 20),
              _EstatisticasCabecalho(
                totalDoacoes: totalDoacoes,
                tipoSanguineo: tipoSanguineo,
                idade: idade,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarraTopo extends StatelessWidget {
  final VoidCallback onVoltar;
  const _BarraTopo({required this.onVoltar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onVoltar,
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 18),
        ),
        const Expanded(
          child: Text('O Meu Perfil',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(width: 18),
      ],
    );
  }
}

class _AvatarEstatico extends StatelessWidget {
  const _AvatarEstatico();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96, height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 52),
    );
  }
}

class _EstatisticasCabecalho extends StatelessWidget {
  final int totalDoacoes;
  final String tipoSanguineo;
  final String idade;

  const _EstatisticasCabecalho({
    required this.totalDoacoes,
    required this.tipoSanguineo,
    required this.idade,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Estatistica(valor: '$totalDoacoes', rotulo: 'Doações'),
        _Separador(),
        _Estatistica(valor: tipoSanguineo, rotulo: 'Tipo Sanguíneo'),
        _Separador(),
        _Estatistica(valor: idade, rotulo: 'Anos'),
      ],
    );
  }
}

class _Estatistica extends StatelessWidget {
  final String valor;
  final String rotulo;
  const _Estatistica({required this.valor, required this.rotulo});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(valor,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(rotulo,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ]),
    );
  }
}

class _Separador extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 32,
      color: Colors.white.withValues(alpha: 0.3),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
