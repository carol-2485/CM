// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String nome,
    required String email,
    required String password,
    required String idade,
    required String tipoSanguineo,
    required String historicoDencas,
    String? dataUltimaDoacao,
  }) async {
    // Cria o utilizador no Firebase Auth
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Guarda os dados adicionais no Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'nome': nome.trim(),
      'email': email.trim(),
      'idade': idade.trim(),
      'tipoSanguineo': tipoSanguineo.trim(),
      'historicoDencas': historicoDencas.trim(),
      'dataUltimaDoacao': dataUltimaDoacao ?? '',
      'isEligible': false,
      'totalDoacoes': 0,
      'criadoEm': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() async => await _auth.signOut();

  Future<void> updateEligibility(bool value) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({'isEligible': value});
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'Utilizador não encontrado.';
      case 'wrong-password': return 'Palavra-passe incorrecta.';
      case 'invalid-credential': return 'Email ou palavra-passe incorrectos.';
      case 'email-already-in-use': return 'Este email já está em uso.';
      case 'weak-password': return 'Palavra-passe demasiado fraca (mínimo 6 caracteres).';
      case 'invalid-email': return 'Email inválido.';
      case 'too-many-requests': return 'Demasiadas tentativas. Tente mais tarde.';
      case 'network-request-failed': return 'Sem ligação à internet.';
      default: return 'Ocorreu um erro: ${e.message}';
    }
  }
}
