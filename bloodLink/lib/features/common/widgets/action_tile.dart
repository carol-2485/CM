// lib/features/common/widgets/action_tile.dart
//
// Tile de acção reutilizável com efeito de hover/pressão animado.
// Usado nas páginas iniciais do utilizador e do centro de saúde
// para apresentar as funcionalidades disponíveis.

import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Tile interactivo com ícone, título, subtítulo e seta de navegação.
///
/// Suporta badge numérico, widget personalizado no lado direito,
/// e efeitos visuais de hover e pressão.
class ActionTile extends StatefulWidget {
  /// Ícone a apresentar no lado esquerdo.
  final IconData icon;

  /// Cor de fundo do ícone (por defeito usa a cor de borda).
  final Color iconBg;

  /// Título principal do tile.
  final String title;

  /// Subtítulo ou descrição breve.
  final String subtitle;

  /// Callback executado ao premir o tile.
  final VoidCallback onTap;

  /// Widget personalizado no lado direito (substitui a seta).
  final Widget? trailing;

  /// Texto do badge numérico (null para ocultar o badge).
  final String? badge;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconBg = AppColors.border,
    this.trailing,
    this.badge,
  });

  @override
  State<ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<ActionTile> {
  bool _premido = false;
  bool _hover = false;

  bool get _destacado => _premido || _hover;

  Color get _corIcone =>
      widget.iconBg == AppColors.border ? AppColors.textMuted : widget.iconBg;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _premido = true),
        onTapUp: (_) {
          setState(() => _premido = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _premido = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _destacado
                ? AppColors.primary.withValues(alpha: 0.06)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _destacado
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.border,
              width: _destacado ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Ícone com fundo animado
              _IconeTile(
                icone: widget.icon,
                corIcone: _corIcone,
                iconBg: widget.iconBg,
                destacado: _destacado,
              ),
              const SizedBox(width: 14),

              // Título e subtítulo
              _TextoTile(
                titulo: widget.title,
                subtitulo: widget.subtitle,
                destacado: _destacado,
              ),

              // Badge numérico (se existir)
              if (widget.badge != null) _Badge(texto: widget.badge!),

              // Trailing ou seta por defeito
              widget.trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _destacado
                        ? AppColors.primary
                        : AppColors.textMuted,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Subwidgets ────────────────────────────────────────────────────────────────

/// Ícone do tile com fundo animado.
class _IconeTile extends StatelessWidget {
  final IconData icone;
  final Color corIcone;
  final Color iconBg;
  final bool destacado;

  const _IconeTile({
    required this.icone,
    required this.corIcone,
    required this.iconBg,
    required this.destacado,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: destacado
            ? corIcone.withValues(alpha: 0.22)
            : iconBg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icone, color: corIcone, size: 22),
    );
  }
}

/// Coluna com título e subtítulo do tile.
class _TextoTile extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool destacado;

  const _TextoTile({
    required this.titulo,
    required this.subtitulo,
    required this.destacado,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: destacado ? AppColors.primary : AppColors.accent,
            ),
          ),
          Text(
            subtitulo,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge numérico vermelho para contadores de não lidos.
class _Badge extends StatelessWidget {
  final String texto;
  const _Badge({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
