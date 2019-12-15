// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

import 'hand.dart';

final tickSize = radians(360 / 12 / 60);

/// A clock hand that is drawn with [CustomPainter]
///
/// The hand's length scales based on the clock's size.
/// This hand is used to build the second and minute hands, and demonstrates
/// building a custom hand.
class Scheibe extends Hand {
  /// Create a const clock [Hand].
  ///
  /// All of the parameters are required and must not be null.
  const Scheibe({
    @required Color color,
    @required this.thickness,
    @required double size,
    @required double angleRadians,
    @required this.angleStart,
    this.text,
  })  : assert(color != null),
        assert(thickness != null),
        assert(size != null),
        assert(angleRadians != null),
        super(
          color: color,
          size: size,
          angleRadians: angleRadians,
        );

  /// How thick the hand should be drawn, in logical pixels.
  final double thickness;
  final double angleStart;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _ScheibenPainter(
            handSize: size,
            lineWidth: thickness,
            angleRadians: angleRadians,
            color: color,
            angleStart: angleStart,
            text: text,
          ),
        ),
      ),
    );
  }
}

/// [CustomPainter] that draws a clock hand.
class _ScheibenPainter extends CustomPainter {
  _ScheibenPainter({
    @required this.handSize,
    @required this.lineWidth,
    @required this.angleRadians,
    @required this.angleStart,
    @required this.color,
    this.text,
  })  : assert(handSize != null),
        assert(lineWidth != null),
        assert(angleRadians != null),
        assert(angleStart != null),
        assert(color != null),
        assert(handSize >= 0.0),
        assert(handSize <= 1.0);

  double handSize;
  double lineWidth;
  double angleStart;
  double angleRadians;
  Color color;

  TextStyle textStyle = TextStyle(color: Colors.black);

  final String text;
  final _textPainter = TextPainter(textDirection: TextDirection.ltr);

  @override
  void paint(Canvas canvas, Size size) {
    var boxSize = size.shortestSide * handSize;
    final xOffset = size.longestSide / 2 - boxSize / 2;
    final yOffset = size.shortestSide / 2 - boxSize / 2;
    final scheibenOffset = Offset(xOffset, yOffset);
    final getRect = (scheibenOffset & Size(boxSize, boxSize));

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.square;

    canvas.drawArc(
        getRect, -math.pi / 2.0 + angleStart, angleRadians, true, linePaint);

    if (text != null) {
      _textPainter.text = TextSpan(text: "...", style: textStyle);
      _textPainter.layout(
        minWidth: 0,
        maxWidth: double.maxFinite,
      );

      final textGabWith = 2.0;
      canvas.save();
      _paint_text(canvas, size, textGabWith);
      canvas.restore();
    }
  }

  void _paint_text(Canvas canvas, Size size, double textGabWith) {
    final radius = size.shortestSide * handSize * 0.5;
    canvas.translate(size.width / 2, size.height / 2 - radius);

    //offset from start of bonding box
    angleStart += tickSize;

    if (angleStart != 0) {
      final d = 2 * radius * math.sin(angleStart / 2);
      final rotationAngle = _calculateRotationAngle(0, angleStart);
      canvas.rotate(rotationAngle);
      canvas.translate(d, 0);
    }

    double angle = angleStart;
    double rotation = angle;
    for (int i = 0; i < text.length; i++) {
      angle = _drawLetter(canvas, text[i], angle, radius);
      rotation += angle;
      if (rotation > angleStart+angleRadians - 7*tickSize) {
        //indicate missing letters
        if (text.length - i > 2) {
          angle = _drawLetter(canvas, ".", angle, radius);
          angle = _drawLetter(canvas, ".", angle, radius);
          angle = _drawLetter(canvas, ".", angle, radius);
        } else {
          //don't even try to get this next time ;)
          i += 1;
          for (; i < text.length; i++) {
            angle = _drawLetter(canvas, text[i], angle, radius);
          }
        }
        break;
      }
    }
  }

  double _drawLetter(
      Canvas canvas, String letter, double prevAngle, double radius) {
    _textPainter.text = TextSpan(text: letter, style: textStyle);
    _textPainter.layout(
      minWidth: 0,
      maxWidth: double.maxFinite,
    );

    final double d = _textPainter.width;
    final double alpha = 2 * math.asin(d / (2 * radius));

    final newAngle = _calculateRotationAngle(prevAngle, alpha);
    canvas.rotate(newAngle);

    _textPainter.paint(canvas, Offset.zero);
    canvas.translate(d, 0);

    return alpha;
  }

  double _calculateRotationAngle(double prevAngle, double alpha) =>
      (alpha + prevAngle) / 2;

  @override
  bool shouldRepaint(_ScheibenPainter oldDelegate) {
    return oldDelegate.handSize != handSize ||
        oldDelegate.lineWidth != lineWidth ||
        oldDelegate.angleRadians != angleRadians ||
        oldDelegate.color != color;
  }
}
