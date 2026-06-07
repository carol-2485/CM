// lib/features/common/services/notificacao_service.dart
//
// Serviço de gestão de notificações do utilizador.
// Fornece streams em tempo real e operações de marcação
// usando Cloud Firestore como backend.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço estático para operações sobre notificações no Firestore.
///
/// Todas as operações filtram automaticamente pelo utilizador autenticado.
class NotificacaoService {
  static final _baseDados = FirebaseFirestore.instance;

  // ── Streams em tempo real ─────────────────────────────────────────────────

  /// Stream de todas as notificações do utilizador, ordenadas por data.
  ///
  /// Emite uma lista actualizada sempre que houver alterações no Firestore.
  /// Limitado a 50 notificações mais recentes para eficiência.
  static Stream<List<Map<String, dynamic>>> notificacoesStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _baseDados
        .collection('notificacoes')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final lista = snapshot.docs.map((doc) {
            final dados = doc.data();
            return {
              'id': doc.id,
              'tipo': dados['tipo'] ?? '',
              'titulo': dados['titulo'] ?? '',
              'mensagem': dados['mensagem'] ?? '',
              'lida': dados['lida'] ?? false,
              'criadaEm': dados['criadaEm'],
              // Campo extra para navegação de mensagens
              'chatId': dados['chatId'],
              'contagem': dados['contagem'] ?? 1,
            };
          }).toList();
          // Ordena no cliente — evita necessidade de índice composto no Firestore
          lista.sort((a, b) {
            final ta = a['criadaEm'];
            final tb = b['criadaEm'];
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return (tb as dynamic).compareTo(ta as dynamic);
          });
          return lista.take(50).toList();
        });
  }

  /// Stream com a contagem de notificações não lidas.
  ///
  /// Usado para actualizar o badge no ícone de notificações.
  static Stream<int> contagemNaoLidasStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    // Filtra apenas por userId para evitar índice composto.
    // A filtragem por 'lida' é feita no cliente.
    return _baseDados
        .collection('notificacoes')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((d) => d.data()['lida'] == false)
            .length);
  }

  // ── Operações de escrita ──────────────────────────────────────────────────

  /// Marca uma notificação específica como lida e repõe o contador de mensagens.
  static Future<void> marcarComoLida(String idNotificacao) async {
    await _baseDados
        .collection('notificacoes')
        .doc(idNotificacao)
        .update({'lida': true, 'contagem': 1});
  }

  /// Marca todas as notificações não lidas do utilizador como lidas.
  ///
  /// Usa batch write para eficiência — operação atómica.
  static Future<void> marcarTodasComoLidas() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Busca todas as notificações do utilizador e filtra no cliente
    final snapshot = await _baseDados
        .collection('notificacoes')
        .where('userId', isEqualTo: uid)
        .get();

    final naoLidas = snapshot.docs
        .where((d) => d.data()['lida'] == false)
        .toList();

    if (naoLidas.isEmpty) return;

    final lote = _baseDados.batch();
    for (final doc in naoLidas) {
      lote.update(doc.reference, {'lida': true});
    }
    await lote.commit();
  }

  /// Cria uma nova notificação para um utilizador.
  ///
  /// Tipos suportados: 'mensagem', 'agendamento_confirmado', 'agendamento_pendente'.
  /// O campo [dadosExtras] permite adicionar metadados opcionais (vagaId, centroId, etc.).
  static Future<void> criarNotificacao({
    required String userId,
    required String tipo,
    required String titulo,
    required String mensagem,
    Map<String, dynamic>? dadosExtras,
  }) async {
    await _baseDados.collection('notificacoes').add({
      'userId': userId,
      'tipo': tipo,
      'titulo': titulo,
      'mensagem': mensagem,
      'lida': false,
      'criadaEm': FieldValue.serverTimestamp(),
      if (dadosExtras != null) ...dadosExtras,
    });
  }
}
