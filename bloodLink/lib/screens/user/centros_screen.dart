// lib/screens/centros_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_colors.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/blood_drop.dart';

// Modelo simples de centro de doação
class _Centro {
  final String nome;
  final String cidade;
  final double lat;
  final double lng;
  double? distancia;
  _Centro(this.nome, this.cidade, this.lat, this.lng);
}

class CentrosScreen extends StatefulWidget {
  const CentrosScreen({super.key});
  @override
  State<CentrosScreen> createState() => _CentrosScreenState();
}

class _CentrosScreenState extends State<CentrosScreen> {
  final MapController _mapCtrl = MapController();

  // Centros reais em Lisboa
  final List<_Centro> _centros = [
    _Centro('Centro de Saúde de Sete Rios', 'Lisboa', 38.7436, -9.1614),
    _Centro('Hospital de Santa Maria', 'Lisboa', 38.7480, -9.1599),
    _Centro('Hospital dos Lusíadas', 'Lisboa', 38.7380, -9.1700),
    _Centro('Hospital da Luz', 'Lisboa', 38.7543, -9.1952),
    _Centro('Instituto Português do Sangue', 'Lisboa', 38.7297, -9.1476),
  ];

  // Posição padrão — Lisboa centro
  static const LatLng _lisbonCenter = LatLng(38.7223, -9.1393);
  LatLng _userPos = _lisbonCenter;
  bool _loading = true;
  _Centro? _selected;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) { _calcDistancias(_lisbonCenter); return; }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _calcDistancias(_lisbonCenter);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low)
          .timeout(const Duration(seconds: 5), onTimeout: () => Position(
            latitude: _lisbonCenter.latitude, longitude: _lisbonCenter.longitude,
            timestamp: DateTime.now(), accuracy: 0, altitude: 0,
            altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0));

      // Verifica se está perto de Portugal (evita coordenadas do emulador)
      final dist = _haversine(pos.latitude, pos.longitude, _lisbonCenter.latitude, _lisbonCenter.longitude);
      final userLatLng = dist > 5000
          ? _lisbonCenter
          : LatLng(pos.latitude, pos.longitude);

      _calcDistancias(userLatLng);
    } catch (_) {
      _calcDistancias(_lisbonCenter);
    }
  }

  void _calcDistancias(LatLng pos) {
    _userPos = pos;
    for (final c in _centros) {
      c.distancia = _haversine(pos.latitude, pos.longitude, c.lat, c.lng);
    }
    _centros.sort((a, b) => (a.distancia ?? 999).compareTo(b.distancia ?? 999));
    if (mounted) setState(() => _loading = false);
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  String _distStr(double? d) {
    if (d == null) return '';
    return '${d.toStringAsFixed(1)} Km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Título
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const BloodDrop(size: 24),
                      const SizedBox(width: 8),
                      const Text('Centros de Doação',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Stepper 1-2-3
                _buildStepper(),

                const SizedBox(height: 12),

                // Mapa OpenStreetMap
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      mapController: _mapCtrl,
                      options: MapOptions(
                        initialCenter: _selected != null
                            ? LatLng(_selected!.lat, _selected!.lng)
                            : _userPos,
                        initialZoom: 12,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.flutter_application_1',
                        ),
                        MarkerLayer(
                          markers: _centros.map((c) {
                            final isSel = _selected?.nome == c.nome;
                            return Marker(
                              point: LatLng(c.lat, c.lng),
                              width: isSel ? 44 : 36,
                              height: isSel ? 44 : 36,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selected = c);
                                  _mapCtrl.move(LatLng(c.lat, c.lng), 14);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSel ? AppColors.primary : AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary, width: isSel ? 3 : 2),
                                  ),
                                  child: Icon(Icons.local_hospital_rounded,
                                      color: isSel ? Colors.white : AppColors.primary,
                                      size: isSel ? 24 : 18),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Lista de centros
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _centros.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 0),
                    itemBuilder: (ctx, i) {
                      final c = _centros[i];
                      final isSel = _selected?.nome == c.nome;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selected = c);
                          _mapCtrl.move(LatLng(c.lat, c.lng), 14);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.nome,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
                                    Text(c.cidade,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Text(_distStr(c.distancia),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _step(1, true),
          _line(false),
          _step(2, false),
          _line(false),
          _step(3, false),
        ],
      ),
    );
  }

  Widget _step(int n, bool active) => Container(
    width: 32, height: 32,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? AppColors.primary : AppColors.surface,
      border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 1.5),
    ),
    child: Center(
      child: Text('$n',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.textMuted)),
    ),
  );

  Widget _line(bool active) => Container(
    width: 40, height: 1.5,
    color: active ? AppColors.primary : AppColors.border,
  );
}
