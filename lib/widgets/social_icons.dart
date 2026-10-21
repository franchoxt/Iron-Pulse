import 'package:flutter/material.dart';

class GoogleIconWidget extends StatelessWidget {
  final double size;
  final Color color;

  const GoogleIconWidget({
    super.key,
    this.size = 20,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleIconPainter(color: color),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  final Color color;

  _GoogleIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - paint.strokeWidth) / 2;

    // Draw arc for the 'G'
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -0.7, 5.0, false, paint);

    // Draw horizontal bar of 'G'
    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius * 0.95, center.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class AppleIconWidget extends StatelessWidget {
  final double size;
  final Color color;

  const AppleIconWidget({
    super.key,
    this.size = 22,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.apple,
      size: size,
      color: color,
    );
  }
}

class CrosshairIconWidget extends StatelessWidget {
  final double size;
  final Color color;

  const CrosshairIconWidget({
    super.key,
    this.size = 20,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CrosshairPainter(color: color),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  final Color color;

  _CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Outer circle
    canvas.drawCircle(center, radius, strokePaint);

    // Inner circle
    canvas.drawCircle(center, radius * 0.52, strokePaint);

    // Center dot
    canvas.drawCircle(center, 1.8, fillPaint);

    // 4 ticks
    const tickLen = 3.5;
    canvas.drawLine(Offset(center.dx, center.dy - radius - tickLen),
        Offset(center.dx, center.dy - radius + 1), strokePaint);
    canvas.drawLine(Offset(center.dx, center.dy + radius - 1),
        Offset(center.dx, center.dy + radius + tickLen), strokePaint);
    canvas.drawLine(Offset(center.dx - radius - tickLen, center.dy),
        Offset(center.dx - radius + 1, center.dy), strokePaint);
    canvas.drawLine(Offset(center.dx + radius - 1, center.dy),
        Offset(center.dx + radius + tickLen, center.dy), strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter oldDelegate) =>
      oldDelegate.color != color;
}
