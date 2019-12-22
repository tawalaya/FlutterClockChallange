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
import 'package:device_calendar/device_calendar.dart';
import 'container_hand.dart';
import 'drawn_hand.dart';
import 'termin.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
/// Total distance traveled by a second or a minute hand, each second or minute,
/// respectively.
final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

final radiansPerSecond = radians(360 / 12 / 60);

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
  List<Event> _events;

  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  Timer _timer;


  List<Color> _eventColors = new List();

  _AnalogClockState(){
    _deviceCalendarPlugin = DeviceCalendarPlugin();


    //XXX fix me generate some nice colors for a few events
    final rnd = new math.Random();
    var baseColors = [Color.fromRGBO(66,133,244,1),Color.fromRGBO(219,68,55,1),Color.fromRGBO(244,160,0,1),Color.fromRGBO(15,157,88,1)];
    for(int i = 0;i<8;i++){
      _eventColors.add(Color.lerp(baseColors[0],baseColors[1],rnd.nextInt(100)/100));
      _eventColors.add(Color.lerp(baseColors[1],baseColors[2],rnd.nextInt(100)/100));
      _eventColors.add(Color.lerp(baseColors[2],baseColors[3],rnd.nextInt(100)/100));
    }
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

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      final lastMidnight = new DateTime(_now.year, _now.month, _now.day);
      final nextMidnight =  new DateTime(_now.year, _now.month, _now.day,23,59);
      final List<Event> events = new List();
      for(Calendar c in calendarsResult?.data){

        var result = await _deviceCalendarPlugin.retrieveEvents(c.id, RetrieveEventsParams(startDate:lastMidnight,endDate: nextMidnight ));
        events.addAll(result?.data);
      }
      setState(() {
        _events = events;
      });
    } on PlatformException catch (e) {
      print(e);
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
      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });
  }

  Color pickColor(String id){
    return _eventColors[id.hashCode%_eventColors.length];
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
      style: TextStyle(color: customTheme.primaryColor,fontSize: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat.yMMMd().format(_now)),
        ],
      ),
    );

    final lastMidnight = new DateTime(_now.year, _now.month, _now.day);
    final lastHour = new DateTime(_now.year, _now.month, _now.day, _now.hour);

    final t = <Termin>[];
    if(_events != null) {
      for (Event e in _events) {
        if(e != null && !e.allDay) {
          t.add(Termin(e.start, e.end, e.title,e.eventId));
        }
      }
    }

    t.sort();

    final clockFace = <Widget>[];

    var end;
    if (_now.hour < 12) {
      end = lastMidnight.add(Duration(hours: 12));
    } else {
      end = lastMidnight.add(Duration(hours: 23, minutes: 59));
    }

    final hourDates = t.where((t) => t.isBefore(end));

    for (Termin t in hourDates) {
      clockFace.add(Scheibe(
        color: pickColor(t.id).withOpacity(0.7),
        size: 1,
        thickness: 2,
        angleRadians: math.max(1,t.length.inHours)*radiansPerHour,
        angleStart:
            t.start.hour%12 * radiansPerHour + t.start.minute * radiansPerSecond,
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

    final minuteDates = t.where(
        (t) => t.includedIn(lastHour, lastHour.add(Duration(minutes: 59))));

    for (Termin t in minuteDates) {
      clockFace.add(Scheibe(
        color: pickColor(t.id).withOpacity(0.7),
        size: 0.95,
        thickness: 2,
        angleRadians: math.max(1,math.min(60,t.length.inMinutes))*radiansPerTick,
        angleStart:
          t.start.minute * radiansPerTick,
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
//          decoration: BoxDecoration(
//            border: Border.all(
//              color: Colors.black,
//            ),
//            shape: BoxShape.circle,
//          ),
          child: Stack(
            children: clockFace,
          ),
        ),
      ),
    );
  }
}
