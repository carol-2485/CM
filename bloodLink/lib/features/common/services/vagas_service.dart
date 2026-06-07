// lib/features/common/services/vagas_service.dart
//
// Serviço de gestão de vagas de doação de sangue.
// Trata das operações de leitura, solicitação, confirmação e recusa
// de vagas, bem como da criação de notificações associadas.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados de uma vaga de doação de sangue.
class Vaga {
  /// Identificador único do documento no Firestore.
  final String id;

  /// ID do centro de saúde a que pertence.
  final String centroId;

  /// Chave de data no formato YYYY-MM-DD.
  final String dataKey;

  /// Hora no formato HH:mm.
  final String hora;

  /// Estado da vaga: 'disponivel', 'pendente', 'confirmado',
  /// 'indisponivel' ou 'concluido'.
  String estado;

  /// ID do utilizador que reservou a vaga (null se livre).
  final String? userId;

  Vaga({
    required this.id,
    required this.centroId,
    required this.dataKey,
    required this.hora,
    required this.estado,
    this.userId,
  });

  /// Constrói uma Vaga a partir de um documento do Firestore.
  factory Vaga.fromFirestore(DocumentSnapshot doc) {
    final dados = doc.data() as Map<String, dynamic>;
    return Vaga(
      id: doc.id,
      centroId: dados['centroId'] ?? '',
      dataKey: dados['dataKey'] ?? '',
      hora: dados['hora'] ?? '',
      estado: dados['estado'] ?? 'disponivel',
      userId: dados['userId'],
    );
  }

  /// Converte a chave de data para um objeto DateTime.
  DateTime get data {
    final partes = dataKey.split('-');
    return DateTime(
      int.parse(partes[0]),
      int.parse(partes[1]),
      int.parse(partes[2]),
    );
  }
}

/// Serviço de operações CRUD sobre vagas de doação.
class VagasService {
  final _baseDados = FirebaseFirestore.instance;

  // ── Utilitários de data ───────────────────────────────────────────────────

  /// Formata uma data para o formato de chave YYYY-MM-DD.
  static String chaveData(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Alias de compatibilidade para [chaveData].
  static String dateKey(DateTime d) => chaveData(d);

  // ── Leitura ──────────────────────────────────────────────────────────────

  /// Devolve as vagas de um centro para uma data específica, ordenadas por hora.
  Future<List<Vaga>> getVagasDoCentro(String centroId, DateTime data) async {
    final chave = chaveData(data);
    final resultado = await _baseDados
        .collection('vagas')
        .where('centroId', isEqualTo: centroId)
        .where('dataKey', isEqualTo: chave)
        .get();

    final vagas = resultado.docs.map(Vaga.fromFirestore).toList();
    vagas.sort((a, b) => a.hora.compareTo(b.hora));
    return vagas;
  }

  // ── Operações do utilizador ───────────────────────────────────────────────

  /// Utilizador solicita uma vaga — estado passa a 'pendente'.
  ///
  /// O centro de saúde recebe o pedido e decide se aceita ou recusa.
  Future<void> solicitarVaga(String vagaId, String userId) async {
    await _baseDados.collection('vagas').doc(vagaId).update({
      'estado': 'pendente',
      'userId': userId,
    });
  }

  // ── Operações do centro ───────────────────────────────────────────────────

  /// Centro confirma a vaga — estado passa a 'confirmado'.
  ///
  /// Cria uma notificação no Firestore para o utilizador.
  Future<void> confirmarVaga(String vagaId) async {
    final doc = await _baseDados.collection('vagas').doc(vagaId).get();
    final dados = doc.data() as Map<String, dynamic>;
    final userId = dados['userId'] as String?;

    // Actualiza o estado
    await _baseDados
        .collection('vagas')
        .doc(vagaId)
        .update({'estado': 'confirmado'});

    // Notifica o utilizador se existir
    if (userId != null) {
      final nomeCentro = await _obterNomeCentro(dados['centroId'] as String?);
      await _criarNotificacao(
        userId: userId,
        vagaId: vagaId,
        centroId: dados['centroId'],
        tipo: 'agendamento_confirmado',
        titulo: 'Agendamento confirmado!',
        mensagem:
            'O seu agendamento para as ${dados['hora']} do dia ${_formatarChave(dados['dataKey'])} em $nomeCentro foi confirmado.',
      );
    }
  }

  /// Centro recusa a vaga — estado volta a 'disponivel'.
  ///
  /// A vaga fica novamente disponível para outros utilizadores.
  Future<void> recusarVaga(String vagaId) async {
    final doc = await _baseDados.collection('vagas').doc(vagaId).get();
    final dados = doc.data() as Map<String, dynamic>;
    final userId = dados['userId'] as String?;

    // Liberta a vaga
    await _baseDados.collection('vagas').doc(vagaId).update({
      'estado': 'disponivel',
      'userId': null,
    });

    // Notifica o utilizador da recusa
    if (userId != null) {
      await _criarNotificacao(
        userId: userId,
        vagaId: vagaId,
        centroId: dados['centroId'],
        tipo: 'agendamento_recusado',
        titulo: 'Agendamento não confirmado',
        mensagem:
            'O seu pedido para as ${dados['hora']} do dia ${_formatarChave(dados['dataKey'])} não foi aceite. Pode reagendar noutra data.',
      );
    }
  }

  /// Altera directamente o estado de uma vaga (uso interno do centro).
  Future<void> alterarEstado(String vagaId, String novoEstado) async {
    await _baseDados
        .collection('vagas')
        .doc(vagaId)
        .update({'estado': novoEstado});
  }

  // ── Utilitários privados ─────────────────────────────────────────────────

  /// Busca o nome do centro pelo ID.
  Future<String> _obterNomeCentro(String? centroId) async {
    if (centroId == null) return 'Centro de Saúde';
    try {
      final doc =
          await _baseDados.collection('centros').doc(centroId).get();
      return doc.data()?['nome'] as String? ?? 'Centro de Saúde';
    } catch (_) {
      return 'Centro de Saúde';
    }
  }

  /// Cria uma notificação no Firestore para o utilizador.
  Future<void> _criarNotificacao({
    required String userId,
    required String vagaId,
    required String? centroId,
    required String tipo,
    required String titulo,
    required String mensagem,
  }) async {
    await _baseDados.collection('notificacoes').add({
      'userId': userId,
      'vagaId': vagaId,
      'centroId': centroId,
      'tipo': tipo,
      'titulo': titulo,
      'mensagem': mensagem,
      'lida': false,
      'criadaEm': FieldValue.serverTimestamp(),
    });
  }

  /// Formata uma chave de data YYYY-MM-DD para DD/MM/AAAA.
  String _formatarChave(String? chave) {
    if (chave == null) return '—';
    final partes = chave.split('-');
    return partes.length == 3
        ? '${partes[2]}/${partes[1]}/${partes[0]}'
        : chave;
  }
}
