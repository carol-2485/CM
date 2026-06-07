// lib/features/common/services/doacoes_service.dart
//
// Serviço responsável pela gestão do histórico de doações de sangue.
// Sincroniza automaticamente agendamentos concluídos e actualiza
// o perfil do utilizador no Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Gere a lógica de negócio relacionada com doações concluídas.
///
/// Responsabilidades:
/// - Detectar agendamentos confirmados cuja data/hora já passou
/// - Marcar essas vagas como 'concluido' no Firestore
/// - Actualizar totalDoacoes e dataUltimaDoacao no perfil do utilizador
/// - Devolver o histórico de doações formatado para apresentação
class DoacoesService {
  static final _baseDados = FirebaseFirestore.instance;

  // ── Sincronização automática ─────────────────────────────────────────────

  /// Verifica agendamentos confirmados cuja data+hora já passou e marca-os
  /// como concluídos, actualizando o contador e a data no perfil do utilizador.
  ///
  /// Este método é chamado ao iniciar os ecrãs Home e Painel para garantir
  /// que o estado está sempre actualizado.
  static Future<void> sincronizarDoacoesConcluidas() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final agora = DateTime.now();

    try {
      // Busca todas as vagas confirmadas do utilizador
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

        // Converte data+hora para DateTime para comparação
        final dataHoraVaga = _converterParaDateTime(chaveData, hora);
        if (dataHoraVaga == null || dataHoraVaga.isAfter(agora)) continue;

        // Marca a vaga como concluída
        await _baseDados
            .collection('vagas')
            .doc(documento.id)
            .update({'estado': 'concluido'});

        novasDoacoes++;

        // Regista a chave da doação mais recente
        if (chaveUltimaDoacao == null ||
            chaveData.compareTo(chaveUltimaDoacao) > 0) {
          chaveUltimaDoacao = chaveData;
        }
      }

      // Actualiza o perfil do utilizador se houve novas doações
      if (novasDoacoes > 0) {
        final docUtilizador =
            await _baseDados.collection('users').doc(uid).get();
        final totalActual =
            (docUtilizador.data()?['totalDoacoes'] ?? 0) as int;

        await _baseDados.collection('users').doc(uid).update({
          'totalDoacoes': totalActual + novasDoacoes,
          if (chaveUltimaDoacao != null)
            'dataUltimaDoacao': chaveUltimaDoacao,
        });
      }
    } catch (erro) {
      // Erro silencioso — não bloquear a UI
      // Em produção seria enviado para um serviço de logging
    }
  }

  // ── Consulta de histórico ────────────────────────────────────────────────

  /// Devolve a lista de doações concluídas do utilizador autenticado,
  /// ordenadas da mais recente para a mais antiga.
  ///
  /// Cada elemento contém:
  /// - id, centroNome, centroId, dataKey, hora, sangueDoado (em litros)
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
          'sangueDoado': 0.45, // 450 ml por doação (valor padrão do IPST)
        });
      }

      // Ordena da mais recente para a mais antiga
      lista.sort((a, b) {
        final chaveA = '${a['dataKey']} ${a['hora']}';
        final chaveB = '${b['dataKey']} ${b['hora']}';
        return chaveB.compareTo(chaveA);
      });

      return lista;
    } catch (_) {
      return [];
    }
  }

  // ── Utilitários ──────────────────────────────────────────────────────────

  /// Converte uma chave de data (YYYY-MM-DD) e hora (HH:mm) para DateTime.
  /// Devolve null se o formato for inválido.
  static DateTime? _converterParaDateTime(String chaveData, String hora) {
    try {
      final partesData = chaveData.split('-');
      final partesHora = hora.split(':');
      if (partesData.length != 3 || partesHora.length != 2) return null;

      return DateTime(
        int.parse(partesData[0]),
        int.parse(partesData[1]),
        int.parse(partesData[2]),
        int.parse(partesHora[0]),
        int.parse(partesHora[1]),
      );
    } catch (_) {
      return null;
    }
  }

  /// Busca o nome do centro de saúde pelo ID.
  static Future<String> _obterNomeCentro(String? centroId) async {
    if (centroId == null) return 'Centro de Saúde';
    try {
      final doc = await _baseDados.collection('centros').doc(centroId).get();
      return doc.data()?['nome'] as String? ?? 'Centro de Saúde';
    } catch (_) {
      return 'Centro de Saúde';
    }
  }

  /// Formata uma chave de data (YYYY-MM-DD) para o formato DD/MM/AAAA.
  static String formatarChaveData(String? chave) {
    if (chave == null) return '—';
    final partes = chave.split('-');
    return partes.length == 3
        ? '${partes[2]}/${partes[1]}/${partes[0]}'
        : chave;
  }
}
