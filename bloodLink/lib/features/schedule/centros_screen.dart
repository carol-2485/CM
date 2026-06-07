// lib/features/schedule/centros_screen.dart
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

class _Centro {
  final String id; // UID do documento no Firestore
  final String nome;
  final String morada;
  final double lat;
  final double lng;
  double? distancia;
  _Centro({required this.id, required this.nome, required this.morada,
      required this.lat, required this.lng});

  String get distDisplay => distancia == null ? '' : '${distancia!.toStringAsFixed(1)} Km';
}

class CentrosScreen extends StatefulWidget {
  const CentrosScreen({super.key});
  @override
  State<CentrosScreen> createState() => _CentrosScreenState();
}

class _CentrosScreenState extends State<CentrosScreen> {
  final MapController _mapCtrl = MapController();
  static const LatLng _lisbonCenter = LatLng(38.7223, -9.1393);

  List<_Centro> _centros = [];
  LatLng _userPos = _lisbonCenter;
  bool _loading = true;
  _Centro? _selected;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadCentros(), _loadLocation()]);
    _sortByDistance();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadCentros() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('centros').get();
      _centros = snap.docs.map((doc) {
        final d = doc.data();
        return _Centro(
          id: doc.id,
          nome: d['nome'] ?? 'Centro',
          morada: d['morada'] ?? '',
          lat: double.tryParse(d['latitude'].toString()) ?? 38.7223,
          lng: double.tryParse(d['longitude'].toString()) ?? -9.1393,
        );
      }).toList();
    } catch (_) {
      // Fallback com centros hardcoded
      _centros = [
        _Centro(id: 'sete_rios', nome: 'Centro de Saúde de Sete Rios', morada: 'Rua Prof. Lima Basto, Lisboa', lat: 38.7436, lng: -9.1614),
        _Centro(id: 'santa_maria', nome: 'Hospital de Santa Maria', morada: 'Av. Prof. Egas Moniz, Lisboa', lat: 38.7480, lng: -9.1599),
        _Centro(id: 'lusiadas', nome: 'Hospital dos Lusíadas', morada: 'Rua Abílio Torres, Lisboa', lat: 38.7380, lng: -9.1700),
        _Centro(id: 'luz', nome: 'Hospital da Luz', morada: 'Av. Lusíada, Lisboa', lat: 38.7543, lng: -9.1952),
        _Centro(id: 'ipst', nome: 'Instituto Português do Sangue', morada: 'Av. Miguel Bombarda, Lisboa', lat: 38.7297, lng: -9.1476),
      ];
    }
  }

  Future<void> _loadLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low)
          .timeout(const Duration(seconds: 5), onTimeout: () => Position(
            latitude: _lisbonCenter.latitude, longitude: _lisbonCenter.longitude,
            timestamp: DateTime.now(), accuracy: 0, altitude: 0,
            altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0));

      final dist = _haversine(pos.latitude, pos.longitude, _lisbonCenter.latitude, _lisbonCenter.longitude);
      _userPos = dist > 5000 ? _lisbonCenter : LatLng(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  void _sortByDistance() {
    for (final c in _centros) {
      c.distancia = _haversine(_userPos.latitude, _userPos.longitude, c.lat, c.lng);
    }
    _centros.sort((a, b) => (a.distancia ?? 999).compareTo(b.distancia ?? 999));
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
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
          : Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  const BloodDrop(size: 22),
                  const SizedBox(width: 8),
                  const Text('Centros de Doação',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ]),
              ),
              const SizedBox(height: 8),
              _buildStepper(),
              const SizedBox(height: 10),

              // Mapa
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 180,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    mapController: _mapCtrl,
                    options: MapOptions(
                      initialCenter: _selected != null ? LatLng(_selected!.lat, _selected!.lng) : _userPos,
                      initialZoom: 12,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.flutter_application_1',
                      ),
                      MarkerLayer(markers: _centros.map((c) {
                        final isSel = _selected?.id == c.id;
                        return Marker(
                          point: LatLng(c.lat, c.lng),
                          width: isSel ? 44 : 36, height: isSel ? 44 : 36,
                          child: GestureDetector(
                            onTap: () { setState(() => _selected = c); _mapCtrl.move(LatLng(c.lat, c.lng), 14); },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primary : AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: isSel ? 3 : 2),
                              ),
                              child: Icon(Icons.local_hospital_rounded,
                                  color: isSel ? Colors.white : AppColors.primary, size: isSel ? 24 : 18),
                            ),
                          ),
                        );
                      }).toList()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Lista
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _centros.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, i) {
                    final c = _centros[i];
                    final isSel = _selected?.id == c.id;
                    return GestureDetector(
                      onTap: () { setState(() => _selected = c); _mapCtrl.move(LatLng(c.lat, c.lng), 14); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                        ),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.nome, style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
                            Text(c.morada, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ])),
                          Text(c.distDisplay, style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                        ]),
                      ),
                    );
                  },
                ),
              ),

              // Botão confirmar
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: _selected == null ? null : () {
                    Navigator.pushNamed(context, AppRoutesUser.agenda, arguments: {
                      'centroId': _selected!.id,
                      'centroNome': _selected!.nome,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Confirmar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ]),
      // ✅ índice 1 = calendário (correcto)
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildStepper() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _step(1, true), _line(false), _step(2, false), _line(false), _step(3, false),
    ]),
  );

  Widget _step(int n, bool active) => Container(
    width: 32, height: 32,
    decoration: BoxDecoration(shape: BoxShape.circle,
      color: active ? AppColors.primary : AppColors.surface,
      border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 1.5)),
    child: Center(child: Text('$n', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
        color: active ? Colors.white : AppColors.textMuted))),
  );

  Widget _line(bool active) =>
      Container(width: 40, height: 1.5, color: active ? AppColors.primary : AppColors.border);
}
