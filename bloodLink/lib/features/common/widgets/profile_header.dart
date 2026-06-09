// lib/features/common/widgets/profile_header.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../services/notificacao_service.dart';

class ProfileHeader extends StatelessWidget {
  final String nome;
  final String subtitle;
  final IconData avatarIcon;
  final VoidCallback onLogout;
  final String? fotoUrl;
  final VoidCallback? onNotificacoesTap;
  final bool mostrarNotificacoes;

  const ProfileHeader({
    super.key,
    required this.nome,
    required this.subtitle,
    required this.onLogout,
    this.avatarIcon = Icons.person_rounded,
    this.fotoUrl,
    this.onNotificacoesTap,
    this.mostrarNotificacoes = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(fotoUrl: fotoUrl, avatarIcon: avatarIcon),
        const SizedBox(width: 12),
        Expanded(child: _Saudacao(nome: nome, subtitle: subtitle)),
        if (mostrarNotificacoes)
          _BotaoNotificacoes(onTap: onNotificacoesTap),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? fotoUrl;
  final IconData avatarIcon;
  const _Avatar({this.fotoUrl, required this.avatarIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
      ),
      child: fotoUrl != null && fotoUrl!.isNotEmpty
          ? ClipOval(child: Image.network(fotoUrl!, fit: BoxFit.cover))
          : Icon(avatarIcon, color: AppColors.primary, size: 26),
    );
  }
}

class _Saudacao extends StatelessWidget {
  final String nome;
  final String subtitle;
  const _Saudacao({required this.nome, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 18, fontFamily: 'Poppins'),
            children: [
              const TextSpan(
                text: 'Olá, ',
                style: TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w500),
              ),
              TextSpan(
                text: '$nome!',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _BotaoNotificacoes extends StatefulWidget {
  final VoidCallback? onTap;
  const _BotaoNotificacoes({this.onTap});

  @override
  State<_BotaoNotificacoes> createState() => _BotaoNotificacoesState();
}

class _BotaoNotificacoesState extends State<_BotaoNotificacoes> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificacaoService.contagemNaoLidasStream(),
      builder: (context, snap) {
        final naoLidas = (snap.hasData && snap.data! > 0) ? snap.data! : 0;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _hover
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _hover ? Icons.notifications_rounded : Icons.notifications_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  if (naoLidas > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          naoLidas > 9 ? '9+' : '$naoLidas',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
