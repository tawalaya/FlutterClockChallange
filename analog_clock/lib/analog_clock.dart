// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:analog_clock/clock_face.dart';
import 'package:analog_clock/scheibe.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'model.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;
import 'package:device_calendar/device_calendar.dart';
import 'drawn_hand.dart';
import 'termin.dart';
import 'package:flutter/services.dart';

/// Total distance traveled by a second or a minute hand, each second or minute,
/// respectively.
final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

final radiansPerSecond = radians(360 / 12 / 60);

final calendarRefreshTime =  Duration(seconds: 15);

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
  DeviceCalendarPlugin _deviceCalendarPlugin;
  List<Termin> _terminArray;

  var _now = DateTime.now();
  Timer _timer;
  Timer _calenderFetcher;

  List<Color> _eventColors = new List();

  _AnalogClockState() {
    _deviceCalendarPlugin = DeviceCalendarPlugin();

    //XXX fix me generate some nice colors for a few events
    final rnd = new math.Random();
    var baseColors = [
      Color.fromRGBO(66, 133, 244, 1),
      Color.fromRGBO(219, 68, 55, 1),
      Color.fromRGBO(244, 160, 0, 1),
      Color.fromRGBO(15, 157, 88, 1)
    ];
    _eventColors.add(Color(0xFF6A6AFF));
    _eventColors.add(Color(0xFF3DE4FC));
    _eventColors.add(Color(0xFF33FDC0));
    _eventColors.add(Color(0xFF4AE371));
    _eventColors.add(Color(0xFFDFE32D));
    _eventColors.add(Color(0xFFFFCB2F));
    _eventColors.add(Color(0xFFFFAC62));
    _eventColors.add(Color(0xFFC87C5B));
    _eventColors.add(Color(0xFFFF7373));
    _eventColors.add(Color(0xFFCB59E8));
  }

  @override
  void initState() {
    super.initState();

    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateModel();
    _retrieveCalendars();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  void _retrieveCalendars() async {
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data) {
          return;
        }
      }

      final lastMidnight = new DateTime(_now.year, _now.month, _now.day);
      final nextMidnight =
          new DateTime(_now.year, _now.month, _now.day, 23, 59);
      final List<Event> events = new List();
      for (String id in widget.model.calenderIds) {
        var result = await _deviceCalendarPlugin.retrieveEvents(
            id,
            RetrieveEventsParams(
                startDate: lastMidnight, endDate: nextMidnight));
        events.addAll(result?.data);
      }

      final terminArray = <Termin>[];
      if (events != null) {
        for (Event e in events) {
          if (e != null && !e.allDay) {
            terminArray.add(Termin(e.start, e.end, e.title, e.eventId));
          }
        }
      }

      terminArray.sort();
      setState(() {
        _terminArray = terminArray;
        _calenderFetcher = new Timer(calendarRefreshTime, _retrieveCalendars);
      });
    } on PlatformException catch (e) {
      log("failed to fetch events",error: e);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _calenderFetcher?.cancel();

    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    _retrieveCalendars();
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });
  }

  Color pickColor(String id) {
    return _eventColors[id.hashCode % _eventColors.length];
  }

  @override
  Widget build(BuildContext context) {
    //XXX: optimize
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
            primaryColor: Color(0xFF383838),
            // Minute hand.
            highlightColor: Color(0xFF4d4d4d),
            // Second hand.
            accentColor: Color(0xFF6b6b6b),
            backgroundColor: Color(0xFFF1F1F1),
          )
        : Theme.of(context).copyWith(
            primaryColor: Color(0xFFF8F8F8),
            highlightColor: Color(0xFFEEEEEE),
            accentColor: Color(0xFFCCCCCC),
            backgroundColor: Color(0xFF3b3b3b),
          );

    final time = DateFormat.Hms().format(DateTime.now());
    double width = MediaQuery.of(context).size.width;
    final infoText = DefaultTextStyle(
      style: TextStyle(color: customTheme.primaryColor, fontSize: width * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat.yMMMd().format(_now)),
        ],
      ),
    );

    final clockFace = <Widget>[];
    clockFace.add(ClockFace(
      primaryColor: customTheme.primaryColor,
      secondaryColor: customTheme.accentColor,
      thickness: 1,
    ));

    if (_terminArray != null) {
      final lastMidnight = new DateTime(_now.year, _now.month, _now.day, 0, 0);
      final lastHour = new DateTime(_now.year, _now.month, _now.day, _now.hour);
      final nextHour = lastHour.add(Duration(hours: 1));

      var start, end;
      if (_now.hour < 12) {
        start = lastMidnight;
        end = lastMidnight.add(Duration(hours: 12));
      } else {
        start = lastMidnight.add(Duration(hours: 12));
        end = lastMidnight.add(Duration(days: 1));
      }

      final eventsToShow = _terminArray.where((t) => t.includedIn(start, end));

      //outer ring
      for (Termin t in eventsToShow) {
        clockFace.add(Scheibe(
          color: pickColor(t.id),
          scale: 0.88,
          thickness: 0.05,
          angleRadians:
              math.max(0, t.lengthIn(start, end).inMinutes) * radiansPerSecond,
          angleStart: t.getRelativeStart(start).hour * radiansPerHour +
              t.getRelativeStart(start).minute * radiansPerSecond,
          text: t.title,
        ));
      }

      clockFace.add(Scheibe(
        color: customTheme.backgroundColor,
        scale: 0.82,
        thickness: 2,
        angleRadians: 2 * math.pi,
        angleStart: 0,
      ));

      final minuteDates = _terminArray.where((t) => t.includedIn(
          lastHour, lastHour.add(Duration(minutes: 59, seconds: 59))));

      //inner ring
      for (Termin t in minuteDates) {
        clockFace.add(Scheibe(
          color: pickColor(t.id),
          scale: 0.825,
          thickness: 0.05,
          angleRadians:
              t.lengthIn(lastHour, nextHour).inMinutes * radiansPerTick,
          angleStart: t.getRelativeStart(lastHour).minute * radiansPerTick,
          text: t.title,
        ));
      }
      if (!widget.model.pieMode) {
        clockFace.add(Scheibe(
          color: customTheme.backgroundColor,
          scale: 0.77,
          thickness: 2,
          angleRadians: 2 * math.pi,
          angleStart: 0,
        ));
      }
    }

    return Semantics.fromProperties(
        properties: SemanticsProperties(
          label: 'Analog clock with time $time',
          value: time,
        ),
        child: Container(
          color: customTheme.backgroundColor,
          child: Container(
            padding: EdgeInsets.all(15),
            child: Stack(
              children: [
                Stack(
                  children: clockFace,
                ),
                DrawnHand(
                  //hour
                  color: customTheme.primaryColor,
                  size: 0.6,
                  thickness: 8,
                  angleRadians:
                  _now.hour * radiansPerHour + (_now.minute / 60) * radiansPerHour,
                ),
                DrawnHand(
                  //minutes
                  color: customTheme.highlightColor,
                  thickness: 6,
                  size: 0.85,
                  angleRadians: _now.minute * radiansPerTick,
                ),
                DrawnHand(
                  //seconds
                  color: customTheme.accentColor,
                  thickness: 2,
                  size: 1,
                  angleRadians: _now.second * radiansPerTick,
                ),
                Scheibe(
                  color: customTheme.primaryColor,
                  scale: 0.04,
                  thickness: 2,
                  angleRadians: 2 * math.pi,
                  angleStart: 0,
                ),
                Positioned(
                  //added info
                  left: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: infoText,
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
