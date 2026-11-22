import 'package:flutter/material.dart';

/// Vector recreation of the selected black-and-gold Amlak Panah mark.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 140});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _BrandLogoPainter()),
      );
}

class _BrandLogoPainter extends CustomPainter {
  static const gold = Color(0xFFE5AD25);
  static const black = Color(0xFF050505);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 716;
    canvas.save();
    canvas.scale(s);
    final fill = Paint()..color = black;
    final stroke = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(const Offset(358, 358), 346, fill);
    canvas.drawCircle(const Offset(358, 358), 346, stroke);
    stroke.strokeWidth = 2.5;
    canvas.drawCircle(const Offset(358, 358), 331, stroke);

    final goldFill = Paint()..color = gold;
    // Skyline
    canvas.drawPath(
      Path()
        ..moveTo(100, 395)..lineTo(100, 250)..lineTo(153, 210)
        ..lineTo(153, 365)..close(),
      goldFill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(170, 365)..lineTo(170, 165)..lineTo(245, 115)
        ..lineTo(245, 365)..close(),
      goldFill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(260, 365)..lineTo(260, 225)..lineTo(310, 190)
        ..lineTo(310, 395)..close(),
      goldFill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(320, 395)..lineTo(320, 285)..lineTo(365, 255)
        ..lineTo(365, 420)..close(),
      goldFill,
    );
    // House roof and walls
    final roof = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 19
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawPath(
      Path()..moveTo(62, 455)..lineTo(240, 315)..lineTo(420, 455),
      roof,
    );
    canvas.drawRect(const Rect.fromLTWH(205, 400, 48, 48), goldFill);
    canvas.drawLine(const Offset(229, 400), const Offset(229, 448),
        Paint()..color = black..strokeWidth = 5);
    canvas.drawLine(const Offset(205, 424), const Offset(253, 424),
        Paint()..color = black..strokeWidth = 5);
    canvas.drawLine(const Offset(62, 455), const Offset(62, 510), roof);

    final text = TextPainter(
      text: const TextSpan(
        text: 'مشاور املاک پناه',
        style: TextStyle(
          color: gold,
          fontSize: 52,
          fontWeight: FontWeight.w700,
          fontFamily: 'sans-serif',
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      maxLines: 1,
    )..layout(maxWidth: 390);
    text.paint(canvas, Offset(306, 370));
    final underline = Paint()
      ..color = gold
      ..strokeWidth = 4;
    canvas.drawLine(const Offset(300, 456), const Offset(640, 456), underline);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
