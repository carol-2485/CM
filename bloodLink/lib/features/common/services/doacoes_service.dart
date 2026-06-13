// lib/features/common/services/doacoes_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoacoesService {
  static final _baseDados = FirebaseFirestore.instance;

  static Future<void> sincronizarDoacoesConcluidas() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final agora = DateTime.now();
    try {
      final resultado = await _baseDados
          .collection('vagas')
          .where('userId', isEqualTo: uid)
          .where('estado', isEqualTo: 'confirmado')
          .get();

      int novasDoacoes = 0;
      String? chaveUltimaDoacao;

      for (final documento in resultado.docs) {
        final dados = documento.data();
        final chaveData = dados['dataKey'] as String? ?? '';
        final hora = dados['hora'] as String? ?? '00:00';
        final dataHoraVaga = _converterParaDateTime(chaveData, hora);
        if (dataHoraVaga == null || dataHoraVaga.isAfter(agora)) continue;
        await _baseDados.collection('vagas').doc(documento.id).update({'estado': 'concluido'});
        novasDoacoes++;
        if (chaveUltimaDoacao == null || chaveData.compareTo(chaveUltimaDoacao) > 0) {
          chaveUltimaDoacao = chaveData;
        }
      }

      // Recalcula sempre o total real de doações concluídas para evitar inconsistências
    final todasConcluidas = await _baseDados
        .collection('vagas')
        .where('userId', isEqualTo: uid)
        .where('estado', isEqualTo: 'concluido')
        .get();

    final totalReal = todasConcluidas.docs.length;

    // Se não houve novas doações, determina a chave da doação mais recente
    if (chaveUltimaDoacao == null && todasConcluidas.docs.isNotEmpty) {
      final chaves = todasConcluidas.docs
          .map((d) => d.data()['dataKey'] as String? ?? '')
          .where((c) => c.isNotEmpty)
          .toList()
        ..sort();
      chaveUltimaDoacao = chaves.last;
    }

    // Actualiza o documento do utilizador com o total real e a data da última doação
    await _baseDados.collection('users').doc(uid).update({
      'totalDoacoes': totalReal,
      if (chaveUltimaDoacao != null) 'dataUltimaDoacao': chaveUltimaDoacao,
    });

  } catch (erro) {
    // Erro silencioso — sincronização em background, não afecta a experiência do utilizador
  }
}

  static Future<List<Map<String, dynamic>>> obterDoacoesConcluidas() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    try {
      final resultado = await _baseDados
          .collection('vagas')
          .where('userId', isEqualTo: uid)
          .where('estado', isEqualTo: 'concluido')
          .get();
      final lista = <Map<String, dynamic>>[];
      for (final documento in resultado.docs) {
        final dados = documento.data();
        final nomeCentro = await _obterNomeCentro(dados['centroId'] as String?);
        lista.add({
          'id': documento.id,
          'centroNome': nomeCentro,
          'centroId': dados['centroId'],
          'dataKey': dados['dataKey'],
          'hora': dados['hora'],
          'sangueDoado': 0.45,
        });
      }
      lista.sort((a, b) {
        final chaveA = '${a['dataKey']} ${a['hora']}';
        final chaveB = '${b['dataKey']} ${b['hora']}';
        return chaveB.compareTo(chaveA);
      });
      return lista;
    } catch (_) { return []; }
  }

  static DateTime? _converterParaDateTime(String chaveData, String hora) {
    try {
      final partesData = chaveData.split('-');
      final partesHora = hora.split(':');
      if (partesData.length != 3 || partesHora.length != 2) return null;
      return DateTime(int.parse(partesData[0]), int.parse(partesData[1]),
          int.parse(partesData[2]), int.parse(partesHora[0]), int.parse(partesHora[1]));
    } catch (_) { return null; }
  }

  static Future<String> _obterNomeCentro(String? centroId) async {
    if (centroId == null) return 'Centro de Saúde';
    try {
      final doc = await _baseDados.collection('centros').doc(centroId).get();
      return doc.data()?['nome'] as String? ?? 'Centro de Saúde';
    } catch (_) { return 'Centro de Saúde'; }
  }

  static String formatarChaveData(String? chave) {
    if (chave == null) return '—';
    final partes = chave.split('-');
    return partes.length == 3 ? '${partes[2]}/${partes[1]}/${partes[0]}' : chave;
  }
}
