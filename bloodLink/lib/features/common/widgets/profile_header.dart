import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String nome;
  final String subtitle;
  final IconData avatarIcon;
  final VoidCallback onLogout;

  const ProfileHeader({
    super.key,
    required this.nome,
    required this.subtitle,
    required this.onLogout,
    this.avatarIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.border,
          child: Icon(avatarIcon, color: AppColors.textMuted, size: 32),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                  children: [
                    const TextSpan(
                      text: 'Olá, ',
                      style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w500),
                    ),
                    TextSpan(
                      text: '$nome!',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
          onPressed: onLogout,
        ),
      ],
    );
  }
}