import 'package:flutter/material.dart';
import '../../../constants/app_routes.dart';
import '../../common/widgets/highlight_card.dart';

class StatusCard extends StatelessWidget {
  final bool isEligible;

  const StatusCard({super.key, required this.isEligible});

  @override
  Widget build(BuildContext context) {
    if (isEligible) {
      return HighlightCard(
        icon: Icons.water_drop_rounded,
        title: 'Apto para Doar',
        subtitle: 'O SEU ESTADO',
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text(
                'Válido',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return HighlightCard(
      icon: Icons.edit_rounded,
      title: 'Avaliar Aptidão',
      subtitle: 'Preencha o seguinte questionário',
      onTap: () => Navigator.pushNamed(context, AppRoutesUser.aptidao),
    );
  }
}