import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// Envia uma mensagem e incrementa o contador do destinatário
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

    // Se quem envia é o user → incrementa o contador do centro
    // Se quem envia é o centro → incrementa o contador do user
    final unreadField = tipo == 'user' ? 'unreadByCentro' : 'unreadByUser';

    batch.update(chatRef, {
      'ultimaMensagem': texto,
      'ultimaHora': FieldValue.serverTimestamp(),
      unreadField: FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Marca o chat como lido por um dos lados ('user' ou 'centro')
  Future<void> marcarComoLido(String chatId, String quem) async {
    final field = quem == 'centro' ? 'unreadByCentro' : 'unreadByUser';
    await _db.collection('chats').doc(chatId).update({field: 0});
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

  Stream<QuerySnapshot> chatsDoCentro(String centroId) {
    return _db
        .collection('chats')
        .where('centroId', isEqualTo: centroId)
        .snapshots();
  }

  /// Total de mensagens não lidas pelo centro (soma de todos os chats)
  Stream<int> unreadCountForCentro(String centroId) {
    return _db
        .collection('chats')
        .where('centroId', isEqualTo: centroId)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            total += (data['unreadByCentro'] ?? 0) as int;
          }
          return total;
        });
  }

  /// Total de mensagens não lidas pelo user (soma de todos os chats)
  Stream<int> unreadCountForUser(String userId) {
    return _db
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            total += (data['unreadByUser'] ?? 0) as int;
          }
          return total;
        });
  }
}