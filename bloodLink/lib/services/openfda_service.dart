// lib/services/openfda_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Integração com a OpenFDA API + lista local de medicamentos
/// que contraindica a doação de sangue.
/// Baseado nas directrizes do IPST (Instituto Português do Sangue e Transplantação)
/// e das normas europeias (Directiva 2004/33/CE).
class OpenFdaService {
  static const String _base = 'https://api.fda.gov/drug/label.json';

  /// Lista local de medicamentos que contraindica PERMANENTEMENTE a doação.
  /// Fonte: IPST, AABB Medication Deferral List, EMA guidelines.
  static const List<String> _exclusaoPermanente = [
    // Teratogénicos (proibição permanente)
    'etretinato', 'etretinate', 'tegison',
    'acitretina', 'acitretin', 'neotigason', 'soriatane',
    'isotretinoína', 'isotretinoin', 'roaccutane', 'accutane',
    'talidomida', 'thalidomide', 'thalomid', 'contergan',
    'dutasterida', 'dutasteride', 'avodart',
    'finasterida', 'finasteride', 'proscar', 'propecia',
    // Anticoagulantes
    'varfarina', 'warfarin', 'coumadin', 'sintrom',
    'dabigatran', 'pradaxa',
    'rivaroxaban', 'xarelto',
    'apixaban', 'eliquis',
    'edoxaban', 'lixiana',
    'heparina', 'heparin', 'clexane', 'fragmin',
    // Imunossupressores
    'ciclosporina', 'cyclosporine', 'sandimmun',
    'metotrexato', 'methotrexate', 'methotrexato',
    'azatioprina', 'azathioprine', 'imuran',
    'micofenolato', 'mycophenolate', 'cellcept',
    // Biológicos/oncológicos
    'adalimumab', 'humira',
    'infliximab', 'remicade',
    'rituximab', 'mabthera',
    // Hormona de crescimento
    'somatropina', 'somatropin',
    // Insulina bovina
    'insulina bovina', 'bovine insulin',
  ];

  /// Lista de medicamentos com exclusão TEMPORÁRIA (mínimo 7 dias após última dose)
  static const List<String> _exclusaoTemporaria = [
    'antibiotico', 'antibiótico', 'antibiotic',
    'amoxicilina', 'amoxicillin', 'amoxil',
    'ampicilina', 'ampicillin',
    'azitromicina', 'azithromycin', 'zithromax',
    'ciprofloxacina', 'ciprofloxacin', 'cipro',
    'doxiciclina', 'doxycycline',
    'metronidazol', 'metronidazole', 'flagyl',
    'aspirina', 'aspirin', 'ácido acetilsalicílico',
    'ibuprofeno', 'ibuprofen', 'brufen', 'advil',
    'cetoprofeno', 'ketoprofen',
    'naproxeno', 'naproxen',
    'antimalárico', 'antimalarial', 'cloroquina', 'chloroquine',
    'mefloquina', 'mefloquine', 'lariam',
  ];

  /// Verifica se um medicamento contraindica a doação de sangue.
  /// Retorna um mapa com: contraindica (bool), tipo (permanente/temporario/nao), mensagem
  Future<Map<String, dynamic>> verificarMedicamento(String nome) async {
    final nomeLower = nome.toLowerCase().trim();

    // 1. Verifica lista local de exclusão permanente
    for (final med in _exclusaoPermanente) {
      if (nomeLower.contains(med) || med.contains(nomeLower)) {
        return {
          'contraindica': true,
          'tipo': 'permanente',
          'mensagem': 'O medicamento "$nome" exclui permanentemente a doação de sangue segundo as directrizes do IPST.',
        };
      }
    }

    // 2. Verifica lista local de exclusão temporária
    for (final med in _exclusaoTemporaria) {
      if (nomeLower.contains(med) || med.contains(nomeLower)) {
        return {
          'contraindica': true,
          'tipo': 'temporario',
          'mensagem': 'O medicamento "$nome" exige um período de espera após a última dose antes de poder doar.',
        };
      }
    }

    // 3. Consulta OpenFDA API para verificação adicional
    try {
      final resultado = await _consultarOpenFDA(nome);
      if (resultado) {
        return {
          'contraindica': true,
          'tipo': 'fda',
          'mensagem': 'A OpenFDA API indica que "$nome" pode contraindicar a doação de sangue.',
        };
      }
    } catch (_) {
      // Se a API falhar, não bloqueia — a lista local já cobre os principais casos
    }

    return {
      'contraindica': false,
      'tipo': 'nao',
      'mensagem': '',
    };
  }

  /// Consulta a OpenFDA API pelo nome do medicamento
  Future<bool> _consultarOpenFDA(String nome) async {
    try {
      final encoded = Uri.encodeComponent('"$nome"');
      final url = '$_base?search=openfda.brand_name:$encoded+openfda.generic_name:$encoded&limit=1';
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return false;

      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return false;

      final label = results.first as Map<String, dynamic>;

      const keywords = [
        'blood donation', 'donate blood', 'blood donor',
        'do not donate', 'cannot donate', 'blood bank',
        'anticoagulant', 'teratogenic', 'pregnancy category x',
      ];
      const fields = [
        'contraindications', 'warnings',
        'warnings_and_cautions', 'boxed_warning',
        'precautions',
      ];

      for (final field in fields) {
        final val = label[field];
        if (val is List && val.isNotEmpty) {
          final text = val.first.toString().toLowerCase();
          if (keywords.any((k) => text.contains(k))) return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Método simples para retrocompatibilidade
  Future<bool> medicamentoContraindica(String nome) async {
    final resultado = await verificarMedicamento(nome);
    return resultado['contraindica'] as bool;
  }
}
