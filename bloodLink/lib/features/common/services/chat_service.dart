// lib/features/common/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notificacao_service.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  Future<String> obterOuCriarChat(String centroId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final chatId = '${uid}_$centroId';

    final doc = await _db.collection('chats').doc(chatId).get();
    if (!doc.exists) {
      await _db.collection('chats').doc(chatId).set({
        'userId': uid,
        'centroId': centroId,
        'criadoEm': FieldValue.serverTimestamp(),
        'ultimaMensagem': '',
        'ultimaHora': FieldValue.serverTimestamp(),
        'unreadByCentro': 0,
        'unreadByUser': 0,
      });
    }
    return chatId;
  }

  /// Envia uma mensagem e incrementa o contador do destinatário.
  /// Se o remetente for o centro, cria também uma notificação para o utilizador.
  Future<void> enviarMensagem(String chatId, String texto, String tipo) async {
    final batch = _db.batch();
    final msgRef = _db.collection('chats').doc(chatId).collection('mensagens').doc();
    final chatRef = _db.collection('chats').doc(chatId);

    batch.set(msgRef, {
      'texto': texto,
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'tipo': tipo,
      'criadaEm': FieldValue.serverTimestamp(),
      'lida': false,
    });

    final campoNaoLido = tipo == 'user' ? 'unreadByCentro' : 'unreadByUser';

    batch.update(chatRef, {
      'ultimaMensagem': texto,
      'ultimaHora': FieldValue.serverTimestamp(),
      campoNaoLido: FieldValue.increment(1),
    });

    await batch.commit();

    // Se for o centro a enviar → notifica o utilizador
    if (tipo == 'centro') {
      final chatDoc = await chatRef.get();
      final userId = chatDoc.data()?['userId'] as String?;

      if (userId != null) {
        String nomeRemetente = 'Centro de Saúde';
        try {
          final centroId = chatDoc.data()?['centroId'] as String?;
          if (centroId != null) {
            final centroDoc = await _db.collection('centros').doc(centroId).get();
            nomeRemetente = centroDoc.data()?['nome'] ?? nomeRemetente;
          }
        } catch (_) {}

        // Verifica se já existe uma notificação de mensagem não lida para este chat.
        // Se existir, incrementa o contador em vez de criar uma nova notificação.
        final notifExistente = await _db
            .collection('notificacoes')
            .where('userId', isEqualTo: userId)
            .where('chatId', isEqualTo: chatId)
            .where('tipo', isEqualTo: 'mensagem')
            .where('lida', isEqualTo: false)
            .get();

        if (notifExistente.docs.isNotEmpty) {
          // Já existe — incrementa a contagem e actualiza a mensagem
          final docRef = notifExistente.docs.first.reference;
          final contagemActual =
              (notifExistente.docs.first.data()['contagem'] as int?) ?? 1;
          await docRef.update({
            'contagem': contagemActual + 1,
            'mensagem': texto.length > 80 ? '${texto.substring(0, 80)}…' : texto,
            'criadaEm': FieldValue.serverTimestamp(),
          });
        } else {
          // Não existe — cria uma nova notificação
          await NotificacaoService.criarNotificacao(
            userId: userId,
            tipo: 'mensagem',
            titulo: 'Nova mensagem de $nomeRemetente',
            mensagem: texto.length > 80 ? '${texto.substring(0, 80)}…' : texto,
            dadosExtras: {'chatId': chatId, 'contagem': 1},
          );
        }
      }
    }
  }

  /// Marca o chat como lido por um dos lados ('user' ou 'centro')
  Future<void> marcarComoLido(String chatId, String quem) async {
    final campo = quem == 'centro' ? 'unreadByCentro' : 'unreadByUser';
    await _db.collection('chats').doc(chatId).update({campo: 0});
  }

  Stream<QuerySnapshot> mensagensStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('mensagens')
        .orderBy('criadaEm', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> chatsDoUtilizador(String userId) {
    return _db
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  /// Stream de chats do centro, ordenados por mensagem mais recente (ordenação no cliente).
  Stream<QuerySnapshot> chatsDoCentro(String centroId) {
    return _db
        .collection('chats')
        .where('centroId', isEqualTo: centroId)
        .snapshots();
  }

  /// Total de mensagens não lidas pelo centro (soma de todos os chats)
  Stream<int> contagemNaoLidasCentro(String centroId) {
    return _db
        .collection('chats')
        .where('centroId', isEqualTo: centroId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        total += (doc.data()['unreadByCentro'] ?? 0) as int;
      }
      return total;
    });
  }

  /// Total de mensagens não lidas pelo utilizador (soma de todos os chats)
  Stream<int> contagemNaoLidasUtilizador(String userId) {
    return _db
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        total += (doc.data()['unreadByUser'] ?? 0) as int;
      }
      return total;
    });
  }

  // Manter compatibilidade com código legado
  Stream<int> unreadCountForUser(String userId) => contagemNaoLidasUtilizador(userId);
  Stream<int> unreadCountForCentro(String centroId) => contagemNaoLidasCentro(centroId);
}
