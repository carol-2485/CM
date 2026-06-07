// lib/features/common/services/vagas_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Vaga {
  final String id;
  final String centroId;
  final String dataKey;
  final String hora;
  String estado; // 'disponivel' | 'pendente' | 'confirmado' | 'indisponivel'
  final String? userId;

  Vaga({
    required this.id,
    required this.centroId,
    required this.dataKey,
    required this.hora,
    required this.estado,
    this.userId,
  });

  factory Vaga.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Vaga(
      id: doc.id,
      centroId: d['centroId'] ?? '',
      dataKey: d['dataKey'] ?? '',
      hora: d['hora'] ?? '',
      estado: d['estado'] ?? 'disponivel',
      userId: d['userId'],
    );
  }

  DateTime get data {
    final parts = dataKey.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}

class VagasService {
  final _db = FirebaseFirestore.instance;

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<List<Vaga>> getVagasDoCentro(String centroId, DateTime data) async {
    final key = dateKey(data);
    final snap = await _db
        .collection('vagas')
        .where('centroId', isEqualTo: centroId)
        .where('dataKey', isEqualTo: key)
        .get();
    final vagas = snap.docs.map((d) => Vaga.fromFirestore(d)).toList();
    vagas.sort((a, b) => a.hora.compareTo(b.hora));
    return vagas;
  }

  /// Utilizador solicita vaga — fica como 'pendente' (aguarda aprovação do centro)
  Future<void> solicitarVaga(String vagaId, String userId) async {
    await _db.collection('vagas').doc(vagaId).update({
      'estado': 'pendente',
      'userId': userId,
    });
  }

  /// Centro confirma a vaga — fica 'confirmado' e cria notificação para o utilizador
  Future<void> confirmarVaga(String vagaId) async {
    final doc = await _db.collection('vagas').doc(vagaId).get();
    final data = doc.data() as Map<String, dynamic>;
    final userId = data['userId'] as String?;

    await _db.collection('vagas').doc(vagaId).update({'estado': 'confirmado'});

    // Cria notificação para o utilizador
    if (userId != null) {
      await _db.collection('notificacoes').add({
        'userId': userId,
        'vagaId': vagaId,
        'centroId': data['centroId'],
        'tipo': 'agendamento_confirmado',
        'mensagem': 'O seu agendamento para as ${data['hora']} do dia ${_formatKey(data['dataKey'])} foi confirmado pelo centro.',
        'lida': false,
        'criadaEm': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Centro recusa a vaga — volta a 'disponivel'
  Future<void> recusarVaga(String vagaId) async {
    final doc = await _db.collection('vagas').doc(vagaId).get();
    final data = doc.data() as Map<String, dynamic>;
    final userId = data['userId'] as String?;

    await _db.collection('vagas').doc(vagaId).update({
      'estado': 'disponivel',
      'userId': null,
    });

    if (userId != null) {
      await _db.collection('notificacoes').add({
        'userId': userId,
        'vagaId': vagaId,
        'tipo': 'agendamento_recusado',
        'mensagem': 'O seu pedido de agendamento para as ${data['hora']} do dia ${_formatKey(data['dataKey'])} não foi aceite.',
        'lida': false,
        'criadaEm': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> alterarEstado(String vagaId, String novoEstado) async {
    await _db.collection('vagas').doc(vagaId).update({'estado': novoEstado});
  }

  String _formatKey(String? key) {
    if (key == null) return '—';
    final p = key.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : key;
  }
}
