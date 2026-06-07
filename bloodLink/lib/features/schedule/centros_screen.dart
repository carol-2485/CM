// lib/features/schedule/centros_screen.dart
//
// Ecrã de selecção do centro de doação de sangue (passo 1 de 3).
// Apresenta um mapa interactivo (OpenStreetMap via flutter_map) com
// marcadores para cada centro, e uma lista ordenada por proximidade
// usando o algoritmo de Haversine com as coordenadas GPS do utilizador.

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../common/widgets/app_bottom_nav.dart';
import '../common/widgets/blood_drop.dart';
import '../schedule/widgets/indicador_passos.dart';

// ── Modelo de dados ───────────────────────────────────────────────────────────

/// Representa um centro de doação de sangue com coordenadas geográficas.
class _CentroDoacao {
  final String id;
  final String nome;
  final String morada;
  final double latitude;
  final double longitude;

  /// Distância calculada em relação ao utilizador (null antes de calcular).
  double? distancia;

  _CentroDoacao({
    required this.id,
    required this.nome,
    required this.morada,
    required this.latitude,
    required this.longitude,
  });

  /// Distância formatada para apresentação (ex: "2.3 Km").
  String get distanciaFormatada =>
      distancia == null ? '' : '${distancia!.toStringAsFixed(1)} Km';
}

// ── Ecrã principal ────────────────────────────────────────────────────────────

/// Ecrã de selecção de centro de doação — passo 1 do fluxo de agendamento.
class CentrosScreen extends StatefulWidget {
  const CentrosScreen({super.key});

  @override
  State<CentrosScreen> createState() => _CentrosScreenState();
}

class _CentrosScreenState extends State<CentrosScreen> {
  // ── Controladores e constantes ───────────────────────────────────────────
  final MapController _controladorMapa = MapController();

  /// Coordenadas de Lisboa como posição padrão.
  static const LatLng _centroLisboa = LatLng(38.7223, -9.1393);

  /// Centros de fallback quando o Firestore não está disponível.
  static final List<_CentroDoacao> _centrosPadrao = [
    _CentroDoacao(id: 'sete_rios', nome: 'Centro de Saúde de Sete Rios',
        morada: 'Rua Prof. Lima Basto, Lisboa',
        latitude: 38.7436, longitude: -9.1614),
    _CentroDoacao(id: 'santa_maria', nome: 'Hospital de Santa Maria',
        morada: 'Av. Prof. Egas Moniz, Lisboa',
        latitude: 38.7480, longitude: -9.1599),
    _CentroDoacao(id: 'lusiadas', nome: 'Hospital dos Lusíadas',
        morada: 'Rua Abílio Torres, Lisboa',
        latitude: 38.7380, longitude: -9.1700),
    _CentroDoacao(id: 'luz', nome: 'Hospital da Luz',
        morada: 'Av. Lusíada, Lisboa',
        latitude: 38.7543, longitude: -9.1952),
    _CentroDoacao(id: 'ipst', nome: 'Instituto Português do Sangue',
        morada: 'Av. Miguel Bombarda, Lisboa',
        latitude: 38.7297, longitude: -9.1476),
  ];

  // ── Estado ───────────────────────────────────────────────────────────────
  List<_CentroDoacao> _centros = [];
  LatLng _posicaoUtilizador = _centroLisboa;
  bool _aCarregar = true;
  _CentroDoacao? _centroSeleccionado;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  // ── Lógica de negócio ─────────────────────────────────────────────────────

  /// Inicializa os centros e a localização em paralelo.
  Future<void> _inicializar() async {
    await Future.wait([_carregarCentros(), _obterLocalizacao()]);
    _ordenarPorProximidade();
    if (mounted) setState(() => _aCarregar = false);
  }

  /// Carrega os centros do Firestore; usa lista de fallback em caso de erro.
  Future<void> _carregarCentros() async {
    try {
      final resultado = await FirebaseFirestore.instance
          .collection('centros')
          .get();
      _centros = resultado.docs.map((doc) {
        final d = doc.data();
        return _CentroDoacao(
          id: doc.id,
          nome: d['nome'] as String? ?? 'Centro',
          morada: d['morada'] as String? ?? '',
          latitude: double.tryParse(d['latitude'].toString()) ?? 38.7223,
          longitude: double.tryParse(d['longitude'].toString()) ?? -9.1393,
        );
      }).toList();
    } catch (_) {
      // Usa centros de fallback quando sem conectividade
      _centros = _centrosPadrao;
    }
  }

  /// Obtém a localização GPS do utilizador com timeout de 5 segundos.
  Future<void> _obterLocalizacao() async {
    try {
      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) return;

      final posicao = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => Position(
          latitude: _centroLisboa.latitude,
          longitude: _centroLisboa.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );

      // Só usa a posição real se estiver dentro da área de Lisboa
      final distancia = _haversine(
        posicao.latitude, posicao.longitude,
        _centroLisboa.latitude, _centroLisboa.longitude,
      );
      _posicaoUtilizador = distancia > 5000
          ? _centroLisboa
          : LatLng(posicao.latitude, posicao.longitude);
    } catch (_) {
      // Fallback silencioso — mantém coordenadas de Lisboa
    }
  }

  /// Calcula as distâncias e ordena os centros por proximidade.
  void _ordenarPorProximidade() {
    for (final centro in _centros) {
      centro.distancia = _haversine(
        _posicaoUtilizador.latitude, _posicaoUtilizador.longitude,
        centro.latitude, centro.longitude,
      );
    }
    _centros.sort(
        (a, b) => (a.distancia ?? 999).compareTo(b.distancia ?? 999));
  }

  /// Fórmula de Haversine — distância em km entre dois pontos geográficos.
  double _haversine(
      double lat1, double lng1, double lat2, double lng2) {
    const raioTerra = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return raioTerra * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// Selecciona um centro e centra o mapa nas suas coordenadas.
  void _seleccionarCentro(_CentroDoacao centro) {
    setState(() => _centroSeleccionado = centro);
    _controladorMapa.move(
        LatLng(centro.latitude, centro.longitude), 14);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _aCarregar
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Título
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: const [
                    BloodDrop(size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Centros de Doação',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),

                // Indicador de passos (passo 1)
                const IndicadorPassos(passoActual: 1),
                const SizedBox(height: 10),

                // Mapa interactivo
                _MapaCentros(
                  centros: _centros,
                  centroSeleccionado: _centroSeleccionado,
                  controladorMapa: _controladorMapa,
                  posicaoUtilizador: _posicaoUtilizador,
                  aoSeleccionar: _seleccionarCentro,
                ),
                const SizedBox(height: 10),

                // Lista de centros
                Expanded(
                  child: _ListaCentros(
                    centros: _centros,
                    centroSeleccionado: _centroSeleccionado,
                    aoSeleccionar: _seleccionarCentro,
                  ),
                ),

                // Botão de confirmação
                _BotaoConfirmar(
                  activo: _centroSeleccionado != null,
                  aoConfirmar: () => Navigator.pushNamed(
                    context,
                    AppRoutesUser.agenda,
                    arguments: {
                      'centroId': _centroSeleccionado!.id,
                      'centroNome': _centroSeleccionado!.nome,
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

/// Mapa interactivo com marcadores para cada centro de doação.
class _MapaCentros extends StatelessWidget {
  final List<_CentroDoacao> centros;
  final _CentroDoacao? centroSeleccionado;
  final MapController controladorMapa;
  final LatLng posicaoUtilizador;
  final void Function(_CentroDoacao) aoSeleccionar;

  const _MapaCentros({
    required this.centros,
    required this.centroSeleccionado,
    required this.controladorMapa,
    required this.posicaoUtilizador,
    required this.aoSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: controladorMapa,
          options: MapOptions(
            initialCenter: centroSeleccionado != null
                ? LatLng(centroSeleccionado!.latitude,
                    centroSeleccionado!.longitude)
                : posicaoUtilizador,
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.bloodlink.app',
            ),
            MarkerLayer(
              markers: centros.map((c) {
                final seleccionado = centroSeleccionado?.id == c.id;
                return Marker(
                  point: LatLng(c.latitude, c.longitude),
                  width: seleccionado ? 48 : 38,
                  height: seleccionado ? 48 : 38,
                  child: GestureDetector(
                    onTap: () => aoSeleccionar(c),
                    child: _MarcadorMapa(seleccionado: seleccionado),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marcador animado no mapa para um centro de doação.
class _MarcadorMapa extends StatelessWidget {
  final bool seleccionado;
  const _MarcadorMapa({required this.seleccionado});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: seleccionado ? AppColors.primary : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary,
          width: seleccionado ? 3 : 2,
        ),
        boxShadow: seleccionado
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 8,
                )
              ]
            : null,
      ),
      child: Icon(
        Icons.local_hospital_rounded,
        color: seleccionado ? Colors.white : AppColors.primary,
        size: seleccionado ? 26 : 20,
      ),
    );
  }
}

/// Lista de centros ordenados por proximidade.
class _ListaCentros extends StatelessWidget {
  final List<_CentroDoacao> centros;
  final _CentroDoacao? centroSeleccionado;
  final void Function(_CentroDoacao) aoSeleccionar;

  const _ListaCentros({
    required this.centros,
    required this.centroSeleccionado,
    required this.aoSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: centros.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (ctx, i) => _TileCentro(
        centro: centros[i],
        seleccionado: centroSeleccionado?.id == centros[i].id,
        aoSeleccionar: () => aoSeleccionar(centros[i]),
      ),
    );
  }
}

/// Tile de um centro de doação na lista.
class _TileCentro extends StatelessWidget {
  final _CentroDoacao centro;
  final bool seleccionado;
  final VoidCallback aoSeleccionar;

  const _TileCentro({
    required this.centro,
    required this.seleccionado,
    required this.aoSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoSeleccionar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: seleccionado
              ? AppColors.primary.withOpacity(0.07)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? AppColors.primary : AppColors.border,
            width: seleccionado ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          // Ícone de hospital
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: seleccionado
                  ? AppColors.primary.withOpacity(0.12)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_hospital_rounded,
              color: seleccionado
                  ? AppColors.primary
                  : AppColors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Nome e morada
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  centro.nome,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: seleccionado
                        ? AppColors.primary
                        : AppColors.accent,
                  ),
                ),
                Text(
                  centro.morada,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // Distância e ícone de estado
          Text(
            centro.distanciaFormatada,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: seleccionado
                  ? AppColors.primary
                  : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            seleccionado
                ? Icons.check_circle_rounded
                : Icons.chevron_right_rounded,
            color: seleccionado
                ? AppColors.primary
                : AppColors.textMuted,
            size: 18,
          ),
        ]),
      ),
    );
  }
}

/// Botão de confirmação de centro seleccionado.
class _BotaoConfirmar extends StatelessWidget {
  final bool activo;
  final VoidCallback aoConfirmar;

  const _BotaoConfirmar({required this.activo, required this.aoConfirmar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: activo ? aoConfirmar : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.border,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        child: const Text(
          'Confirmar',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white),
        ),
      ),
    );
  }
}
