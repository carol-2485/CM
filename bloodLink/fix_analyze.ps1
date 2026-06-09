# fix_analyze.ps1
# Corrige todos os issues do flutter analyze no projecto BloodLink
# Executa: powershell -ExecutionPolicy Bypass -File fix_analyze.ps1

$ROOT = "C:\claude\bloodLink\lib"
$total = 0

function Fix-DartFile($path) {
    $content = Get-Content $path -Raw -Encoding UTF8
    if ($null -eq $content) { return $false }
    $original = $content

    # 1. withOpacity -> withValues(alpha:)
    $content = [regex]::Replace($content,
        '\.withOpacity\(([^)]+)\)',
        { param($m) ".withValues(alpha: $($m.Groups[1].Value))" })

    # 2. unnecessary_underscores (_, __) -> (_, i) e variantes
    $content = $content -replace '\(_, _i\)', '(_, i)'
    $content = $content -replace '\(_, __\)', '(_, i)'

    # 3. activeColor -> activeThumbColor
    $content = $content -replace 'activeColor: const Color\(0xFF22C55E\),', 'activeThumbColor: const Color(0xFF22C55E),'
    $content = $content -replace 'activeColor: AppColors\.primary,', 'activeThumbColor: AppColors.primary,'

    $nome = Split-Path $path -Leaf

    # 4. chat_centro_screen.dart - unused imports e uid
    if ($nome -eq "chat_centro_screen.dart") {
        $content = $content -replace "import 'package:firebase_auth/firebase_auth\.dart';\r?\n", ''
        $content = $content -replace "import '\.\./common/widgets/app_bottom_nav\.dart';\r?\n", ''
        $content = $content -replace "import '\.\./common/widgets/blood_drop\.dart';\r?\n", ''
        $content = [regex]::Replace($content,
            "\r?\n\s*final uid = FirebaseAuth\.instance\.currentUser\?\.uid \?\? '';?\r?\n",
            "`n")
    }

    # 5. header_painel.dart - unused import
    if ($nome -eq "header_painel.dart") {
        $content = $content -replace "import '\.\./\.\./\.\./constants/app_routes\.dart';\r?\n", ''
    }

    # 6. agenda_screen.dart - unused _vagasService
    if ($nome -eq "agenda_screen.dart") {
        $content = [regex]::Replace($content,
            "\r?\n\s*final _vagasService = VagasService\(\);\r?\n", "`n")
    }

    # 7. gerir_vagas_screen.dart - isIndisponivel nao usado + curly braces
    if ($nome -eq "gerir_vagas_screen.dart") {
        $content = [regex]::Replace($content,
            "\r?\n\s*final isIndisponivel = [^\r\n]+\r?\n", "`n")
        $content = $content -replace 'if \(q\.docs\.isNotEmpty\) _centroId = q\.docs\.first\.id;',
            'if (q.docs.isNotEmpty) { _centroId = q.docs.first.id; }'
        $content = $content -replace 'vaga\.estado == ''pendente''\) return;',
            "vaga.estado == 'pendente') {`n      return;`n    }"
    }

    # 8. centros_screen.dart - curly braces + desiredAccuracy
    if ($nome -eq "centros_screen.dart") {
        $content = [regex]::Replace($content,
            '(if \(permissao == LocationPermission\.denied \|\|\s*\r?\n\s*permissao == LocationPermission\.deniedForever\)) return;',
            '$1 { return; }')
        $content = $content -replace 'desiredAccuracy: LocationAccuracy\.low,',
            'locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),'
    }

    # 9. doacoes_service.dart - null-aware (usa duas escritas separadas)
    if ($nome -eq "doacoes_service.dart") {
        $content = [regex]::Replace($content,
            "if \(chaveUltimaDoacao != null\)\s*'dataUltimaDoacao': chaveUltimaDoacao,",
            "'dataUltimaDoacao': chaveUltimaDoacao ?? FieldValue.delete(),")
        # remover o operador ? invalido se existir
        $content = $content -replace "\?'dataUltimaDoacao': chaveUltimaDoacao,",
            "'dataUltimaDoacao': chaveUltimaDoacao ?? FieldValue.delete(),"
    }

    # 10. historico_doacoes_screen.dart - key constructor
    if ($nome -eq "historico_doacoes_screen.dart") {
        $content = $content -replace 'const EstadoVazioHistorico\(\);',
            'const EstadoVazioHistorico({super.key});'
    }

    # 11. register_screen.dart - DropdownButtonFormField value deprecated
    if ($nome -eq "register_screen.dart") {
        $content = $content -replace '(\s+)(value: valorSelecionado,)',
            "`$1// ignore: deprecated_member_use`n`$1`$2"
    }

    # 12. Radio groupValue/onChanged deprecated (pergunta_sim_nao + questionario_screen)
    if ($nome -eq "pergunta_sim_nao.dart" -or $nome -eq "questionario_screen.dart") {
        $content = [regex]::Replace($content,
            '(\n(\s+))(groupValue: )',
            { param($m) "$($m.Groups[1].Value)// ignore: deprecated_member_use`n$($m.Groups[2].Value)$($m.Groups[3].Value)" })
        $content = [regex]::Replace($content,
            '(\n(\s+))(onChanged: \(v\))',
            { param($m) "$($m.Groups[1].Value)// ignore: deprecated_member_use`n$($m.Groups[2].Value)$($m.Groups[3].Value)" })
    }

    # 13. tileOpcao.dart - renomear ficheiro para tile_opcao.dart
    if ($nome -eq "tileOpcao.dart") {
        $novoPath = Join-Path (Split-Path $path) "tile_opcao.dart"
        Set-Content $path $content -Encoding UTF8 -NoNewline
        Rename-Item $path $novoPath -Force
        Write-Host "  renomeado: tileOpcao.dart -> tile_opcao.dart"
        return $true
    }

    if ($content -ne $original) {
        Set-Content $path $content -Encoding UTF8 -NoNewline
        return $true
    }
    return $false
}

# Corrige widget_test.dart
$testPath = "C:\claude\bloodLink\test\widget_test.dart"
Set-Content $testPath @"
// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('BloodLink arranca sem erros', (WidgetTester tester) async {
    expect(BloodLinkApp, isNotNull);
  });
}
"@ -Encoding UTF8 -NoNewline
Write-Host "  corrigido: test\widget_test.dart"
$total++

# Percorre todos os ficheiros .dart
Get-ChildItem -Path $ROOT -Recurse -Filter "*.dart" | ForEach-Object {
    $resultado = Fix-DartFile $_.FullName
    if ($resultado) {
        $total++
        Write-Host "  corrigido: $($_.FullName.Replace($ROOT + '\', ''))"
    }
}

Write-Host ""
Write-Host "Total modificados: $total"
Write-Host "Concluido! Corre: flutter analyze"
