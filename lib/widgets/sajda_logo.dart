import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sajda/theme.dart';

class SajdaLogo extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? accentColor;
  
  const SajdaLogo({
    super.key,
    this.size = 120,
    this.primaryColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? IslamicColors.emeraldGreen;
    final accent = accentColor ?? IslamicColors.roseGold;
    
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SajdaLogoPainter(
          primaryColor: primary,
          accentColor: accent,
        ),
      ),
    );
  }
}

class SajdaLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  
  const SajdaLogoPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;
    
    // Dégradé pour le cercle principal
    final circleGradient = RadialGradient(
      colors: [
        const Color(0xFFF5F1E8),
        const Color(0xFFE8DCC6),
      ],
    );
    
    final circlePaint = Paint()
      ..shader = circleGradient.createShader(
        Rect.fromCircle(center: center, radius: radius)
      )
      ..style = PaintingStyle.fill;
    
    // Cercle principal
    canvas.drawCircle(center, radius, circlePaint);
    
    // Bordure dorée
    final borderPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, radius, borderPaint);
    
    // Dessiner les feuilles (couronne)
    _drawLeaves(canvas, center, radius * 0.85);
    
    // Dessiner le tasbih (chapelet)
    _drawTasbih(canvas, center, radius * 0.3);
    
    // Dessiner le texte SAJDA
    _drawSajdaText(canvas, center, size);
  }
  
  void _drawLeaves(Canvas canvas, Offset center, double radius) {
    final leafPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    
    // Dessiner les feuilles autour du cercle
    for (int i = 0; i < 16; i++) {
      final angle = (i * 22.5) * (3.14159 / 180);
      
      canvas.save();
      canvas.translate(
        center.dx + radius * 1.1 * math.cos(angle),
        center.dy + radius * 1.1 * math.sin(angle),
      );
      canvas.rotate(angle + 3.14159 / 2);
      
      // Forme de feuille
      final leafPath = Path();
      leafPath.moveTo(0, -8);
      leafPath.quadraticBezierTo(-4, -4, 0, 0);
      leafPath.quadraticBezierTo(4, -4, 0, -8);
      
      canvas.drawPath(leafPath, leafPaint);
      canvas.restore();
    }
  }
  
  void _drawTasbih(Canvas canvas, Offset center, double radius) {
    final beadPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.fill;
    
    final beadRadius = 4.0;
    final numBeads = 12;
    
    // Dessiner les perles du tasbih en cercle
    for (int i = 0; i < numBeads; i++) {
      final angle = (i * 30) * (3.14159 / 180);
      final beadX = center.dx + radius * math.cos(angle);
      final beadY = center.dy + radius * math.sin(angle);
      
      canvas.drawCircle(Offset(beadX, beadY), beadRadius, beadPaint);
    }
    
    // Perle centrale plus grande (perle de direction)
    final centerBeadPaint = Paint()
      ..color = const Color(0xFF654321)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 1.2),
      beadRadius * 1.5,
      centerBeadPaint,
    );
  }
  
  void _drawSajdaText(Canvas canvas, Offset center, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'SAJDA',
        style: TextStyle(
          color: primaryColor,
          fontSize: size.width * 0.18,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}