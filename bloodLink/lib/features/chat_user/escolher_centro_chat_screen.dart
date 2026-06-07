// lib/features/clarify/escolher_centro_chat_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../common/widgets/app_bottom_nav.dart';
import '../common/widgets/blood_drop.dart';
import 'chat_centro_screen.dart';

class EscolherCentroChatScreen extends StatefulWidget {
  const EscolherCentroChatScreen({super.key});
  @override
  State<EscolherCentroChatScreen> createState() => _EscolherCentroChatScreenState();
}

class _EscolherCentroChatScreenState extends State<EscolherCentroChatScreen> {
  List<Map<String, dynamic>> _centros = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCentros();
  }

  Future<void> _loadCentros() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('centros').get();
      _centros = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const BloodDrop(size: 22),
              const SizedBox(width: 8),
              const Text('Chat com Centro de Saúde',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ]),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Escolha o centro para enviar a sua dúvida',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _centros.isEmpty
                    ? const Center(child: Text('Nenhum centro disponível.',
                        style: TextStyle(color: AppColors.textMuted)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _centros.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final c = _centros[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ChatCentroScreen(
                                centroId: c['id'] as String,
                                centroNome: c['nome'] as String? ?? 'Centro',
                              ),
                            )),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.local_hospital_rounded,
                                      color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(c['nome'] as String? ?? 'Centro',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
                                  Text(c['morada'] as String? ?? '',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ])),
                                const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
                              ]),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}
