// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Modification Copyright 2020 Sebastian Werner and Andreas Salzmann.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import 'hand.dart';

/// A clock hand that is drawn with [CustomPainter]
///
/// The hand's length scales based on the clock's size.
/// This hand is used to build the second and minute hands, and demonstrates
/// building a custom hand.
class DrawnHand extends Hand {
  /// Create a const clock [Hand].
  ///
  /// All of the parameters are required and must not be null.
  const DrawnHand({
    @required Color color,
    @required this.thickness,
    @required double size,
    @required double angleRadians,
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.expand(
        child: CustomPaint(
          isComplex: true,
          willChange: true,
          painter: _HandPainter(
            handSize: size,
            lineWidth: thickness,
            angleRadians: angleRadians,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// [CustomPainter] that draws a clock hand.
class _HandPainter extends CustomPainter {
  Paint linePaint;
  Paint shadow;


  _HandPainter({
    @required this.handSize,
    @required this.lineWidth,
    @required this.angleRadians,
    @required this.color,
  })  : assert(handSize != null),
        assert(lineWidth != null),
        assert(angleRadians != null),
        assert(color != null),
        assert(handSize >= 0.0),
        assert(handSize <= 1.0){
    linePaint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    shadow = Paint()..color=Color.fromRGBO(0, 0, 0, 1)..strokeWidth = lineWidth..strokeCap = StrokeCap.round..blendMode=BlendMode.softLight;
  }

  double handSize;
  double lineWidth;
  double angleRadians;
  Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = (Offset.zero & size).center;
    // We want to start at the top, not at the x-axis, so add pi/2.
    final angle = angleRadians - math.pi / 2.0;
    final length = size.shortestSide * 0.5 * handSize;
    final position = center + Offset(math.cos(angle), math.sin(angle)) * length;
    final start = (center +
        Offset(math.cos(angle), math.sin(angle)) * (size.shortestSide) *0.2*0.07)
        +Offset(math.cos(angle), math.sin(angle)) * 0.2*lineWidth;

    canvas.drawLine(start+Offset(2,2), position+Offset(2*0.9,2*0.9),shadow );
    canvas.drawLine(start, position, linePaint);
    
  }

  @override
  bool shouldRepaint(_HandPainter oldDelegate) {
    return oldDelegate.handSize != handSize ||
        oldDelegate.lineWidth != lineWidth ||
        oldDelegate.angleRadians != angleRadians ||
        oldDelegate.color != color;;
  }
}
