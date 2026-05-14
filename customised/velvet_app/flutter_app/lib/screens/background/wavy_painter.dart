import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  final Color color;

  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..lineTo(0, size.height - 100)
      ..quadraticBezierTo(
          size.width / 4, size.height, size.width / 2, size.height - 50)
      ..quadraticBezierTo(
          size.width * 3 / 4, size.height - 100, size.width, size.height - 50)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WavePainterOne extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade100
      ..style = PaintingStyle.fill;

    final path = Path()
      ..lineTo(0, size.height - 100)
      ..quadraticBezierTo(
          size.width / 4, size.height, size.width / 2, size.height - 50)
      ..quadraticBezierTo(
          size.width * 3 / 4, size.height - 100, size.width, size.height - 50)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
