import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';

class MarkerGenerator {
  static Future<BitmapDescriptor> createCapsuleMarker({
    required String text,
    required Color color,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double fontSize = 22.0;
    const double padding = 12.0;
    const double pointerHeight = 12.0;
    const double radius = 10.0;

    final Paint paint = Paint()..color = color;
    final Paint textPaint = Paint()..color = Colors.white;

    final TextSpan textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final double width = textPainter.width + (padding * 2);
    final double height = textPainter.height + (padding * 2);

    final RRect rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(radius),
    );
    canvas.drawRRect(rRect, paint);

    final Path path = Path();
    path.moveTo(width / 2 - 8, height);
    path.lineTo(width / 2, height + pointerHeight);
    path.lineTo(width / 2 + 8, height);
    path.close();
    canvas.drawPath(path, paint);

    textPainter.paint(canvas, Offset(padding, padding));

    final ui.Image image = await pictureRecorder.endRecording().toImage(
        width.toInt(),
        (height + pointerHeight).toInt()
    );
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> createIconMarker({
    required IconData iconData,
    required Color color,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double size = 48.0;
    const double iconSize = 28.0;

    final Paint circlePaint = Paint()..color = color;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, circlePaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawCircle(const Offset(size / 2, size / 2), (size / 2) - 2, borderPaint);

    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: iconData.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
}