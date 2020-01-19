// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Modification Copyright 2020 Sebastian Werner and Andreas Salzmann.

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
    @required this.scale,
    @required this.second,
  })  : assert(primaryColor != null),
        assert(thickness != null);

  final Color primaryColor;
  final Color secondaryColor;
  final double scale;
  final double thickness;
  final int second;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _ClockFacePainter(
            primary: primaryColor,
            secondary:secondaryColor,
            scale: scale,
            second:second
          ),
          willChange: false,
          isComplex: true,
        ),
      ),
    );
  }
}

/// [CustomPainter] that draws a clock hand.
class _ClockFacePainter extends CustomPainter {
  Paint hourPaint;
  Paint secondPaint;
  Paint quaterHourPaint;

  final int second;
  final Color primary;
  final Color secondary;
  final double scale;

  _ClockFacePainter({
    @required this.primary, this.secondary, this.scale, this.second
  })  : assert(primary != null), super(){

    hourPaint = Paint()
      ..color = primary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    quaterHourPaint = Paint()
      ..color = primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    secondPaint = Paint()
      ..color = primary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
  }



  
  @override
  void paint(Canvas canvas, Size drawSize) {

    var boxSize = 0.98*drawSize.shortestSide * this.scale / 2;
    final xOffset = drawSize.longestSide / 2 ;
    final yOffset = drawSize.shortestSide / 2 ;

    canvas.save();

    canvas.translate(xOffset, yOffset);
    canvas.rotate(radians(-90));
    for(int i = 0;i<60;i+=1) {
      Paint paint = secondPaint;
      int size = 10;
      bool draw = false;

      if(i%15 == 0) {
          paint = quaterHourPaint;
          size = 12;
          draw = true;
      } else if(i%5 == 0){
        paint = hourPaint;
        size = 10;
        draw = true;
      }

      draw = draw || i == second;// || i == (second-1)%60 || i == (second+1)%60;

      if (i == second){
        size+=3;
      }

      if(draw) {
        canvas.drawLine(Offset(boxSize - size, 0), Offset(boxSize, 0), paint);
      }

      canvas.rotate(tickSize);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ClockFacePainter oldDelegate) {
    return oldDelegate.second != second || oldDelegate.primary != primary || oldDelegate.secondary != secondary;
  }

}
