// lib/features/common/widgets/avatar_editavel.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/app_colors.dart';

/// Resultado da escolha de foto pelo utilizador.
class ResultadoFoto {
  final XFile? ficheiro; // null se cancelou ou removeu
  final bool removida;  // true se escolheu "Remover foto"
  const ResultadoFoto({this.ficheiro, this.removida = false});
}

/// Avatar circular editável com botão de câmara.
class AvatarEditavel extends StatelessWidget {
  final String? fotoUrl;
  final bool carregando;
  final VoidCallback onEditar;
  final double raio;
  final Color corFundo;
  final Color corIcone;

  const AvatarEditavel({
    super.key,
    this.fotoUrl,
    required this.carregando,
    required this.onEditar,
    this.raio = 48,
    this.corFundo = Colors.white,
    this.corIcone = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final temFoto = fotoUrl != null && fotoUrl!.isNotEmpty;
    return GestureDetector(
      onTap: onEditar,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          _CirculoAvatar(
              fotoUrl: fotoUrl, temFoto: temFoto,
              carregando: carregando, raio: raio, corFundo: corFundo),
          _BotaoCamara(corIcone: corIcone),
        ],
      ),
    );
  }
}

class _CirculoAvatar extends StatelessWidget {
  final String? fotoUrl;
  final bool temFoto, carregando;
  final double raio;
  final Color corFundo;
  const _CirculoAvatar({required this.fotoUrl, required this.temFoto,
      required this.carregando, required this.raio, required this.corFundo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: raio * 2, height: raio * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: corFundo.withOpacity(0.2),
        border: Border.all(color: corFundo, width: 3),
      ),
      child: carregando
          ? CircularProgressIndicator(color: corFundo, strokeWidth: 2)
          : ClipOval(
              child: temFoto
                  ? Image.network(fotoUrl!, fit: BoxFit.cover)
                  : Icon(Icons.person_rounded, color: corFundo, size: raio),
            ),
    );
  }
}

class _BotaoCamara extends StatelessWidget {
  final Color corIcone;
  const _BotaoCamara({required this.corIcone});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: Colors.white, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4)],
      ),
      child: Icon(Icons.camera_alt_rounded, color: corIcone, size: 16),
    );
  }
}

/// Mostra o seletor de foto e devolve [ResultadoFoto].
Future<ResultadoFoto> mostrarSeletorFoto2(BuildContext context,
    {bool temFotoActual = false}) async {
  final picker = ImagePicker();

  final opcao = await showModalBottomSheet<_OpcaoFotoEnum>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _BottomSheetFoto(temFotoActual: temFotoActual),
  );

  if (opcao == null) return const ResultadoFoto(); // cancelou
  if (opcao == _OpcaoFotoEnum.remover) return const ResultadoFoto(removida: true);

  final source =
      opcao == _OpcaoFotoEnum.camera ? ImageSource.camera : ImageSource.gallery;

  final xfile = await picker.pickImage(
      source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);

  return ResultadoFoto(ficheiro: xfile);
}

/// Compat: devolve XFile ou null (null = cancelou; usa [mostrarSeletorFoto2] para remover)
Future<XFile?> mostrarSeletorFotoXFile(BuildContext context,
    {bool temFotoActual = false}) async {
  final r = await mostrarSeletorFoto2(context, temFotoActual: temFotoActual);
  return r.ficheiro;
}

/// Compat mobile: devolve File
Future<File?> mostrarSeletorFoto(BuildContext context,
    {bool temFotoActual = false}) async {
  final xfile = await mostrarSeletorFotoXFile(context, temFotoActual: temFotoActual);
  if (xfile == null || kIsWeb) return null;
  return File(xfile.path);
}

enum _OpcaoFotoEnum { camera, galeria, remover }

class _BottomSheetFoto extends StatelessWidget {
  final bool temFotoActual;
  const _BottomSheetFoto({required this.temFotoActual});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Escolher foto',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.accent)),
            const SizedBox(height: 16),
            if (!kIsWeb) ...[
              _OpcaoItem(
                icone: Icons.camera_alt_rounded,
                titulo: 'Tirar fotografia',
                onTap: () => Navigator.pop(context, _OpcaoFotoEnum.camera),
              ),
              const SizedBox(height: 8),
            ],
            _OpcaoItem(
              icone: Icons.photo_library_rounded,
              titulo: 'Escolher da galeria',
              onTap: () => Navigator.pop(context, _OpcaoFotoEnum.galeria),
            ),
            if (temFotoActual) ...[
              const SizedBox(height: 8),
              _OpcaoRemover(onTap: () => Navigator.pop(context, _OpcaoFotoEnum.remover)),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpcaoItem extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final VoidCallback onTap;
  const _OpcaoItem({required this.icone, required this.titulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icone, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.accent)),
        ]),
      ),
    );
  }
}

class _OpcaoRemover extends StatelessWidget {
  final VoidCallback onTap;
  const _OpcaoRemover({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.2)),
        ),
        child: const Row(children: [
          Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
          SizedBox(width: 14),
          Text('Remover foto', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.error)),
        ]),
      ),
    );
  }
}
