// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:analog_clock/scheibe.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

import 'container_hand.dart';
import 'drawn_hand.dart';
import 'termin.dart';

/// Total distance traveled by a second or a minute hand, each second or minute,
/// respectively.
final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

/// A basic analog clock.
///
/// You can do better than this!
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  Timer _timer;

  var _termine = [];

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      final lastMidnight = new DateTime(_now.year, _now.month, _now.day);
      final start = lastMidnight.add(Duration(
          hours: math.Random().nextInt(24),
          minutes: math.Random().nextInt(59)));
      final end = start.add(Duration(
          hours: math.Random().nextInt(2), minutes: math.Random().nextInt(59)));

      _termine.add(Termin(start, end, "Test i"));
      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // There are many ways to apply themes to your clock. Some are:
    //  - Inherit the parent Theme (see ClockCustomizer in the
    //    flutter_clock_helper package).
    //  - Override the Theme.of(context).colorScheme.
    //  - Create your own [ThemeData], demonstrated in [AnalogClock].
    //  - Create a map of [Color]s to custom keys, demonstrated in
    //    [DigitalClock].
    final customTheme = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).copyWith(
            // Hour hand.
            primaryColor: Color(0xFF4285F4),
            // Minute hand.
            highlightColor: Color(0xFF8AB4F8),
            // Second hand.
            accentColor: Color(0xFF669DF6),
            backgroundColor: Color(0xFFD2E3FC),
          )
        : Theme.of(context).copyWith(
            primaryColor: Color(0xFFD2E3FC),
            highlightColor: Color(0xFF4285F4),
            accentColor: Color(0xFF8AB4F8),
            backgroundColor: Color(0xFF3C4043),
          );

    final time = DateFormat.Hms().format(DateTime.now());
    final weatherInfo = DefaultTextStyle(
      style: TextStyle(color: customTheme.primaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_temperature),
          Text(_temperatureRange),
          Text(_condition),
          Text(_location),
        ],
      ),
    );

    final lastMidnight = new DateTime(_now.year, _now.month, _now.day);
    final lastHour = new DateTime(_now.year, _now.month, _now.day, _now.hour);

    final clockFace = <Widget>[];

    var end;
    if (_now.hour < 12) {
      end = lastMidnight.add(Duration(hours: 12));
    } else {
      end = lastMidnight.add(Duration(hours: 23, minutes: 59));
    }

    final hourDates = _termine.where((t) => t.isBefore(end));

    for (Termin t in hourDates) {
      clockFace.add(Scheibe(
        color: Colors.blue.withOpacity(0.5),
        size: 1,
        thickness: 2,
        angleRadians: t.length * radiansPerHour,
        angleStart:
            t.start.hour * radiansPerHour + t.start.minute * radiansPerTick,
        text: t.title,
      ));
    }

    clockFace.add(Scheibe(
      color: customTheme.backgroundColor,
      size: 0.95,
      thickness: 2,
      angleRadians: 2 * math.pi,
      angleStart: 0,
    ));

    final minuteDates = _termine.where(
        (t) => t.includedIn(lastHour, lastHour.add(Duration(minutes: 59))));

    for (Termin t in hourDates) {
      clockFace.add(Scheibe(
        color: Colors.red.withOpacity(0.5),
        size: 0.95,
        thickness: 2,
        angleRadians: t.length * radiansPerHour,
        angleStart:
            t.start.hour * radiansPerHour + t.start.minute * radiansPerTick,
        text: t.title,
      ));
    }

    clockFace.add(Scheibe(
      color: customTheme.backgroundColor,
      size: 0.90,
      thickness: 2,
      angleRadians: 2 * math.pi,
      angleStart: 0,
    ));

    clockFace.addAll([
      DrawnHand(
        //seconds
        color: customTheme.accentColor,
        thickness: 4,
        size: 1,
        angleRadians: _now.second * radiansPerTick,
      ),
      DrawnHand(
        //minutes
        color: customTheme.highlightColor,
        thickness: 16,
        size: 0.9,
        angleRadians: _now.minute * radiansPerTick,
      ),
      // Example of a hand drawn with [Container].
      ContainerHand(
        //hour
        color: Colors.transparent,
        size: 0.5,
        angleRadians:
            _now.hour * radiansPerHour + (_now.minute / 60) * radiansPerHour,
        child: Transform.translate(
          offset: Offset(0.0, -60.0),
          child: Container(
            width: 32,
            height: 150,
            decoration: BoxDecoration(
              color: customTheme.primaryColor,
            ),
          ),
        ),
      ),
      Scheibe(
        color: customTheme.primaryColor,
        size: 0.04,
        thickness: 2,
        angleRadians: 2 * math.pi,
        angleStart: 0,
      ),
      Positioned(
        //added infos
        left: 0,
        bottom: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: weatherInfo,
        ),
      ),
    ]);

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Analog clock with time $time',
        value: time,
      ),
      child: Container(
        color: customTheme.backgroundColor,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
            ),
            shape: BoxShape.circle,
          ),
          child: Stack(
            children: clockFace,
          ),
        ),
      ),
    );
  }
}
