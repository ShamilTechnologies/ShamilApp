import 'package:flutter/material.dart';

// Premium Pattern Painter for background effects
class PremiumPatternPainter extends CustomPainter {
  final Color color;

  PremiumPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Create organic flowing pattern
    for (int i = 0; i < 3; i++) {
      final startX = size.width * (0.2 + i * 0.3);
      final startY = size.height * (0.1 + i * 0.2);

      path.reset();
      path.moveTo(startX, startY);

      // Create flowing curves
      path.quadraticBezierTo(
        startX + 50,
        startY + 30,
        startX + 80,
        startY + 10,
      );
      path.quadraticBezierTo(
        startX + 120,
        startY - 10,
        startX + 150,
        startY + 20,
      );
      path.quadraticBezierTo(
        startX + 180,
        startY + 50,
        startX + 200,
        startY + 30,
      );

      canvas.drawPath(path, paint);
    }

    // Add scattered dots for texture
    for (int i = 0; i < 20; i++) {
      final x = size.width * (i * 0.051) % size.width;
      final y = size.height * (i * 0.073) % size.height;
      canvas.drawCircle(
        Offset(x, y),
        2.0 + (i % 3),
        paint..color = color.withOpacity(0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Modern Pattern Painter for enhanced background effects
class ModernPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Create flowing geometric patterns
    for (int i = 0; i < 4; i++) {
      final centerX = size.width * (0.25 + i * 0.2);
      final centerY = size.height * (0.3 + i * 0.15);

      // Draw concentric circles
      for (int j = 1; j <= 3; j++) {
        canvas.drawCircle(
          Offset(centerX, centerY),
          j * 20.0,
          paint..color = Colors.white.withOpacity(0.03 * j),
        );
      }
    }

    // Add flowing lines
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final startX = size.width * (i * 0.2);
      final startY = size.height * 0.1;

      path.reset();
      path.moveTo(startX, startY);
      path.quadraticBezierTo(
        startX + 30,
        startY + 60,
        startX + 60,
        startY + 40,
      );
      path.quadraticBezierTo(
        startX + 90,
        startY + 20,
        startX + 120,
        startY + 80,
      );

      canvas.drawPath(path, paint..color = Colors.white.withOpacity(0.04));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Enhanced Pattern Painter for sophisticated background effects
class EnhancedPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    // Create sophisticated geometric patterns
    for (int i = 0; i < 6; i++) {
      final centerX = size.width * (0.15 + i * 0.15);
      final centerY = size.height * (0.2 + (i % 3) * 0.25);

      // Draw layered shapes
      for (int j = 1; j <= 2; j++) {
        // Squares with rounded corners
        final rect = Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: j * 25.0,
          height: j * 25.0,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
        canvas.drawRRect(
            rrect, paint..color = Colors.white.withOpacity(0.02 * j));
      }
    }

    // Add flowing connecting lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    for (int i = 0; i < 4; i++) {
      final startX = size.width * (i * 0.25);
      final startY = size.height * 0.15;

      path.reset();
      path.moveTo(startX, startY);
      path.quadraticBezierTo(
        startX + 40,
        startY + 80,
        startX + 80,
        startY + 60,
      );
      path.quadraticBezierTo(
        startX + 120,
        startY + 40,
        startX + 160,
        startY + 100,
      );

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
