// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

final tickSize = radians(360 / 60);

class ClockFace extends StatelessWidget {

  const ClockFace({
    @required this.primaryColor,
    @required this.secondaryColor,
    @required this.thickness,
  })  : assert(primaryColor != null),
        assert(thickness != null);

  final double thickness;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _ClockFacePainter(
            primary: primaryColor,
            secondary:secondaryColor,
          ),
        ),
      ),
    );
  }
}

/// [CustomPainter] that draws a clock hand.
class _ClockFacePainter extends CustomPainter {
  Paint primaryPaint;
  Paint secondaryPaint;
  Paint thirdPaint;

  _ClockFacePainter({
    @required this.primary, this.secondary,
  })  : assert(primary != null), super(){

    primaryPaint = Paint()
      ..color = primary.withOpacity(0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    thirdPaint = Paint()
      ..color = primary.withOpacity(0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    secondaryPaint = Paint()
      ..color = secondary.withOpacity(0.8)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.square;
  }

  final Color primary;
  final Color secondary;

  
  @override
  void paint(Canvas canvas, Size drawSize) {

    var boxSize = drawSize.shortestSide /2 ;
    final xOffset = drawSize.longestSide / 2 ;
    final yOffset = drawSize.shortestSide / 2 ;

    canvas.save();
    canvas.translate(xOffset, yOffset);
    for(int i = 0;i<60;i+=1) {

    if(i%15 == 0) {
      canvas.drawLine(Offset(boxSize-12, 0), Offset(boxSize, 0), thirdPaint);
    } else if(i%5 == 0){
      canvas.drawLine(Offset(boxSize-10, 0), Offset(boxSize, 0), primaryPaint);
    } else {
      canvas.drawLine(Offset(boxSize-5, 0), Offset(boxSize, 0), secondaryPaint);
    }
      canvas.rotate(tickSize);
    }
    canvas.restore();

  }

  @override
  bool shouldRepaint(_ClockFacePainter oldDelegate) {
    return oldDelegate.primary != primary || oldDelegate.secondary != secondary;
  }

}
