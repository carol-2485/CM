// lib/features/auth/services/auth_service.dart
//
// Serviço de autenticação e gestão do perfil do utilizador.
// Encapsula todas as operações do Firebase Auth e Firestore
// relacionadas com a conta do utilizador.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço centralizado de autenticação e dados do utilizador.
///
/// Usa Firebase Authentication para autenticar e Cloud Firestore
/// para persistir o perfil do utilizador.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _baseDados = FirebaseFirestore.instance;

  // ── Estado de autenticação ────────────────────────────────────────────────

  /// Utilizador actualmente autenticado (null se não há sessão).
  User? get utilizadorActual => _auth.currentUser;

  /// Alias de compatibilidade.
  User? get currentUser => _auth.currentUser;

  /// Stream do estado de autenticação (emite ao fazer login/logout).
  Stream<User?> get estadoAuth => _auth.authStateChanges();

  /// Alias de compatibilidade.
  Stream<User?> get authState => _auth.authStateChanges();

  // ── Operações de autenticação ─────────────────────────────────────────────

  /// Autentica o utilizador com email e palavra-passe.
  ///
  /// Lança [FirebaseAuthException] em caso de credenciais inválidas.
  Future<UserCredential> iniciarSessao(
      String email, String palavraPasse) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: palavraPasse,
    );
  }

  /// Alias de compatibilidade para [iniciarSessao].
  Future<UserCredential> login(String email, String palavraPasse) =>
      iniciarSessao(email, palavraPasse);

  /// Cria uma nova conta de utilizador e o perfil correspondente no Firestore.
  ///
  /// O perfil é inicializado com isEligible = false e totalDoacoes = 0.
  Future<UserCredential> registar({
    required String nome,
    required String email,
    required String palavraPasse,
    required String idade,
    required String tipoSanguineo,
    required String historicoDencas,
    String? dataUltimaDoacao,
  }) async {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: palavraPasse,
    );

    // Cria o documento de perfil no Firestore
    await _baseDados.collection('users').doc(credencial.user!.uid).set({
      'nome': nome.trim(),
      'email': email.trim(),
      'idade': idade.trim(),
      'tipoSanguineo': tipoSanguineo.trim(),
      'historicoDencas': historicoDencas.trim(),
      'dataUltimaDoacao': dataUltimaDoacao ?? '',
      'fotoUrl': '',
      'isEligible': false,
      'totalDoacoes': 0,
      'criadoEm': FieldValue.serverTimestamp(),
    });

    return credencial;
  }

  /// Alias de compatibilidade para [registar].
  Future<UserCredential> register({
    required String nome,
    required String email,
    required String password,
    required String idade,
    required String tipoSanguineo,
    required String historicoDencas,
    String? dataUltimaDoacao,
  }) =>
      registar(
        nome: nome,
        email: email,
        palavraPasse: password,
        idade: idade,
        tipoSanguineo: tipoSanguineo,
        historicoDencas: historicoDencas,
        dataUltimaDoacao: dataUltimaDoacao,
      );

  /// Termina a sessão actual do utilizador.
  Future<void> terminarSessao() async => await _auth.signOut();

  /// Alias de compatibilidade para [terminarSessao].
  Future<void> logout() => terminarSessao();

  /// Envia email de reposição de palavra-passe.
  Future<void> enviarReposicaoPalavraPasse(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Alias de compatibilidade.
  Future<void> sendPasswordReset(String email) =>
      enviarReposicaoPalavraPasse(email);

  // ── Gestão do perfil ──────────────────────────────────────────────────────

  /// Actualiza o estado de aptidão para doação do utilizador.
  Future<void> actualizarAptidao(bool valor) async {
    final uid = utilizadorActual?.uid;
    if (uid == null) return;
    await _baseDados
        .collection('users')
        .doc(uid)
        .update({'isEligible': valor});
  }

  /// Alias de compatibilidade para [actualizarAptidao].
  Future<void> updateEligibility(bool valor) => actualizarAptidao(valor);

  /// Actualiza o URL da foto de perfil do utilizador.
  Future<void> actualizarFotoPerfil(String url) async {
    final uid = utilizadorActual?.uid;
    if (uid == null) return;
    await _baseDados
        .collection('users')
        .doc(uid)
        .update({'fotoUrl': url});
  }

  /// Alias de compatibilidade.
  Future<void> atualizarFotoPerfil(String url) => actualizarFotoPerfil(url);

  /// Devolve os dados do perfil do utilizador autenticado.
  ///
  /// Retorna null se não houver sessão activa ou o documento não existir.
  Future<Map<String, dynamic>?> getUserData() async {
    final uid = utilizadorActual?.uid;
    if (uid == null) return null;
    final doc = await _baseDados.collection('users').doc(uid).get();
    return doc.data();
  }

  // ── Tratamento de erros ───────────────────────────────────────────────────

  /// Converte um [FirebaseAuthException] numa mensagem legível em português.
  String mensagemDeErro(FirebaseAuthException erro) {
    switch (erro.code) {
      case 'user-not-found':
        return 'Utilizador não encontrado.';
      case 'wrong-password':
        return 'Palavra-passe incorrecta.';
      case 'invalid-credential':
        return 'Email ou palavra-passe incorrectos.';
      case 'email-already-in-use':
        return 'Este email já está em uso.';
      case 'weak-password':
        return 'Palavra-passe demasiado fraca (mínimo 6 caracteres).';
      case 'invalid-email':
        return 'Email inválido.';
      case 'too-many-requests':
        return 'Demasiadas tentativas. Tente mais tarde.';
      case 'network-request-failed':
        return 'Sem ligação à internet.';
      default:
        return 'Ocorreu um erro: ${erro.message}';
    }
  }

  /// Alias de compatibilidade para [mensagemDeErro].
  String getErrorMessage(FirebaseAuthException e) => mensagemDeErro(e);
}
