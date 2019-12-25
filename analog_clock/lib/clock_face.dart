// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

final tickSize = radians(360 / 12 );

class ClockFace extends StatelessWidget {

  const ClockFace({
    @required this.color,
    @required this.thickness,
  })  : assert(color != null),
        assert(thickness != null);

  final double thickness;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _ClockFacePainter(
            color: color,
          ),
        ),
      ),
    );
  }
}

/// [CustomPainter] that draws a clock hand.
class _ClockFacePainter extends CustomPainter {
  _ClockFacePainter({
    @required this.color,
  })  : assert(color != null);

  Color color;
  @override
  void paint(Canvas canvas, Size drawSize) {

    var boxSize = drawSize.shortestSide /2 ;
    final xOffset = drawSize.longestSide / 2 ;
    final yOffset = drawSize.shortestSide / 2 ;

    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeCap = StrokeCap.square;

    canvas.save();
    canvas.translate(xOffset, yOffset);
    for(int i = 0;i<12;i++) {
      canvas.drawRect(Rect.fromCenter(center:Offset(boxSize-boxSize*0.08, 0),width: boxSize*0.10,height: 10), paint);
      canvas.rotate(tickSize);
    }
    canvas.restore();

  }

  @override
  bool shouldRepaint(_ClockFacePainter oldDelegate) {
    return oldDelegate.color != color;
  }

}
