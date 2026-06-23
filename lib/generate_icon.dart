import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(1024, 1024);
  
  final painter = ZoWayIconPainter();
  painter.paint(canvas, size);
  
  final picture = recorder.endRecording();
  final image = await picture.toImage(1024, 1024);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  
  final file = File('assets/images/zoway_icon.png');
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  
  print('✅ Icône générée !');
  exit(0);
}

class ZoWayIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fond orange arrondi
    final bgPaint = Paint()..color = const Color(0xFFFF6B00);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.22),
    );
    canvas.drawRRect(rect, bgPaint);

    // Oeil gauche blanc
    final oeilBlanc = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.35, h * 0.50),
        width: w * 0.28,
        height: h * 0.32,
      ),
      oeilBlanc,
    );

    // Oeil droit blanc
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.65, h * 0.50),
        width: w * 0.28,
        height: h * 0.32,
      ),
      oeilBlanc,
    );

    // Pupille gauche
    final pupillePaint = Paint()..color = const Color(0xFF1A237E);
    canvas.drawCircle(Offset(w * 0.37, h * 0.52), w * 0.10, pupillePaint);

    // Pupille droite
    canvas.drawCircle(Offset(w * 0.67, h * 0.52), w * 0.10, pupillePaint);

    // Reflets
    final refletPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.39, h * 0.48), w * 0.04, refletPaint);
    canvas.drawCircle(Offset(w * 0.69, h * 0.48), w * 0.04, refletPaint);

    // Sourire
    final sourirePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.05
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final sourirePath = ui.Path();
    sourirePath.moveTo(w * 0.30, h * 0.70);
    sourirePath.quadraticBezierTo(w * 0.50, h * 0.85, w * 0.70, h * 0.70);
    canvas.drawPath(sourirePath, sourirePaint);

    // Épingle dorée
    final epinglePaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(Offset(w * 0.50, h * 0.12), w * 0.09, epinglePaint);

    // Tige épingle
    final tigePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.50, h * 0.21),
      Offset(w * 0.50, h * 0.30),
      tigePaint,
    );

    // Point centre épingle
    final centrePaint = Paint()..color = const Color(0xFFFF6B00);
    canvas.drawCircle(Offset(w * 0.50, h * 0.12), w * 0.04, centrePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}