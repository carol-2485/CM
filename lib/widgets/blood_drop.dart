// lib/widgets/blood_drop.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class BloodDrop extends StatelessWidget {
  final double size;
  const BloodDrop({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.75, size),
      painter: _DropPainter(),
    );
  }
}

class _DropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary..style = PaintingStyle.fill;
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w / 2, 0);
    path.cubicTo(w * 1.1, h * 0.4, w * 1.1, h * 0.75, w / 2, h * 0.9);
    path.cubicTo(-w * 0.1, h * 0.75, -w * 0.1, h * 0.4, w / 2, 0);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
