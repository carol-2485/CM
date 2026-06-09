// lib/features/historico/historico_doacoes_screen.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../common/services/doacoes_service.dart';
import '../common/widgets/app_bottom_nav.dart';

class HistoricoDoacoesScreen extends StatefulWidget {
  const HistoricoDoacoesScreen({super.key});
  @override
  State<HistoricoDoacoesScreen> createState() => _HistoricoDoacoesScreenState();
}

class _HistoricoDoacoesScreenState extends State<HistoricoDoacoesScreen> {
  List<Map<String, dynamic>> _doacoes = [];
  bool _aCarregar = true;
  int get _totalDoacoes => _doacoes.length;
  double get _totalSangue => _totalDoacoes * 0.45;
  int get _vidasSalvas => _totalDoacoes * 3;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    final lista = await DoacoesService.obterDoacoesConcluidas();
    if (mounted) setState(() { _doacoes = lista; _aCarregar = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CabecalhoHistorico(
              totalDoacoes: _totalDoacoes,
              totalSangue: _totalSangue,
              vidasSalvas: _vidasSalvas,
              aoVoltar: () => Navigator.pop(context),
            ),
          ),
          if (_aCarregar)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_doacoes.isEmpty)
            const SliverFillRemaining(child: EstadoVazioHistorico())
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(child: _LabelContador(total: _totalDoacoes)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => CartaoDoacao(doacao: _doacoes[i], numero: _totalDoacoes - i),
                  childCount: _doacoes.length,
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class CabecalhoHistorico extends StatelessWidget {
  final int totalDoacoes;
  final double totalSangue;
  final int vidasSalvas;
  final VoidCallback aoVoltar;
  const CabecalhoHistorico({
    super.key,
    required this.totalDoacoes, required this.totalSangue,
    required this.vidasSalvas, required this.aoVoltar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            children: [
              _BarraNavegacao(aoVoltar: aoVoltar),
              const SizedBox(height: 24),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 8),
              const Text('O Seu Impacto', style: TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 20),
              Row(
                children: [
                  ContadorEstatistica(valor: '$totalDoacoes', rotulo: 'Doações\nrealizadas'),
                  const _SeparadorVertical(),
                  ContadorEstatistica(valor: '${totalSangue.toStringAsFixed(1)}L', rotulo: 'Sangue\ndoado'),
                  const _SeparadorVertical(),
                  ContadorEstatistica(valor: '$vidasSalvas', rotulo: 'Vidas\nsalvas'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarraNavegacao extends StatelessWidget {
  final VoidCallback aoVoltar;
  const _BarraNavegacao({required this.aoVoltar});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: aoVoltar,
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
        ),
        const Expanded(
          child: Text('Histórico de Doações',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(width: 18),
      ],
    );
  }
}

class ContadorEstatistica extends StatelessWidget {
  final String valor;
  final String rotulo;
  const ContadorEstatistica({super.key, required this.valor, required this.rotulo});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(rotulo, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.white70, height: 1.3)),
      ]),
    );
  }
}

class _SeparadorVertical extends StatelessWidget {
  const _SeparadorVertical();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 36,
      color: Colors.white.withValues(alpha: 0.25),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

class _LabelContador extends StatelessWidget {
  final int total;
  const _LabelContador({required this.total});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.history_rounded, size: 16, color: AppColors.primary),
      const SizedBox(width: 6),
      Text('$total doaç${total == 1 ? 'ão' : 'ões'} realizadas',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
    ]);
  }
}

class CartaoDoacao extends StatelessWidget {
  final Map<String, dynamic> doacao;
  final int numero;
  const CartaoDoacao({super.key, required this.doacao, required this.numero});

  String _dia(String chave) { final p = chave.split('-'); return p.length == 3 ? p[2] : '—'; }
  String _mes(String chave) {
    final p = chave.split('-');
    if (p.length != 3) return '';
    const meses = ['JAN','FEV','MAR','ABR','MAI','JUN','JUL','AGO','SET','OUT','NOV','DEZ'];
    final i = int.tryParse(p[1]);
    return (i != null && i >= 1 && i <= 12) ? meses[i - 1] : '';
  }

  @override
  Widget build(BuildContext context) {
    final chaveData = doacao['dataKey'] as String? ?? '';
    final sangue = (doacao['sangueDoado'] as num?)?.toDouble() ?? 0.45;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        _BlocoData(dia: _dia(chaveData), mes: _mes(chaveData)),
        Container(width: 1, height: 64, color: AppColors.border),
        Expanded(child: _InfoDoacao(
          numero: numero,
          nomeCentro: doacao['centroNome'] as String? ?? '—',
          hora: doacao['hora'] as String? ?? '—',
          mlSangue: (sangue * 1000).toStringAsFixed(0),
        )),
      ]),
    );
  }
}

class _BlocoData extends StatelessWidget {
  final String dia, mes;
  const _BlocoData({required this.dia, required this.mes});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(dia, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
        Text(mes, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
      ]),
    );
  }
}

class _InfoDoacao extends StatelessWidget {
  final int numero;
  final String nomeCentro, hora, mlSangue;
  const _InfoDoacao({required this.numero, required this.nomeCentro, required this.hora, required this.mlSangue});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [_BadgeNumero(numero: numero), const Spacer(), const _BadgeConcluida()]),
        const SizedBox(height: 6),
        Text(nomeCentro,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(hora, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(width: 14),
          const Icon(Icons.water_drop_rounded, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text('$mlSangue ml',
              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

class _BadgeNumero extends StatelessWidget {
  final int numero;
  const _BadgeNumero({required this.numero});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('Doação #$numero',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
    );
  }
}

class _BadgeConcluida extends StatelessWidget {
  const _BadgeConcluida();
  @override
  Widget build(BuildContext context) {
    return const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 16),
      SizedBox(width: 4),
      Text('Concluída', style: TextStyle(fontSize: 11, color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
    ]);
  }
}

class EstadoVazioHistorico extends StatelessWidget {
  const EstadoVazioHistorico({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07), shape: BoxShape.circle),
            child: const Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Ainda sem doações',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent)),
          const SizedBox(height: 8),
          const Text('Quando realizares a tua primeira doação ela aparecerá aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5)),
        ]),
      ),
    );
  }
}
