// lib/features/common/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço de chat entre utilizador e centro de saúde.
/// Estrutura Firestore:
///   chats/{chatId}/
///     userId, centroId, criadoEm, ultimaMensagem
///   chats/{chatId}/mensagens/{msgId}/
///     texto, senderId, tipo ('user'|'centro'), criadaEm, lida
class ChatService {
  final _db = FirebaseFirestore.instance;

  /// Cria ou obtém o chat entre este utilizador e um centro
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
      });
    }
    return chatId;
  }

  /// Envia uma mensagem
  Future<void> enviarMensagem(String chatId, String texto, String tipo) async {
    final batch = _db.batch();
    final msgRef = _db.collection('chats').doc(chatId).collection('mensagens').doc();
    batch.set(msgRef, {
      'texto': texto,
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'tipo': tipo,
      'criadaEm': FieldValue.serverTimestamp(),
      'lida': false,
    });
    batch.update(_db.collection('chats').doc(chatId), {
      'ultimaMensagem': texto,
      'ultimaHora': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Stream de mensagens de um chat
  Stream<QuerySnapshot> mensagensStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('mensagens')
        .orderBy('criadaEm', descending: false)
        .snapshots();
  }

  /// Chats do utilizador actual
  Stream<QuerySnapshot> chatsDoUtilizador(String userId) {
    return _db
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  /// Chats de um centro
  Stream<QuerySnapshot> chatsDoCentro(String centroId) {
    return _db
        .collection('chats')
        .where('centroId', isEqualTo: centroId)
        .snapshots();
  }
}
