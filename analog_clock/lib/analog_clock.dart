// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Modification Copyright 2020 Sebastian Werner and Andreas Salzmann.
import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:analog_clock/arc.dart';
import 'package:analog_clock/clock_face.dart';
import 'package:analog_clock/disk.dart';
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
//TODO: increase for production
final calendarRefreshTime = Duration(minutes: 2);

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
  List<Termin> _eventArray;

  var _now = DateTime.now();
  Timer _timer;
  Timer _calenderFetcher;

  List<Color> _eventColors = new List();

  _AnalogClockState() {
    _deviceCalendarPlugin = DeviceCalendarPlugin();

    //XXX fix me generate some nice colors for a few events
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
      final nextMidnight = lastMidnight.add(Duration(days: 1));
      final List<Event> events = new List();
      for (String id in widget.model.calenderIds) {
        var result = await _deviceCalendarPlugin.retrieveEvents(
            id,
            RetrieveEventsParams(
                startDate: lastMidnight, endDate: nextMidnight));
        events.addAll(result?.data);
      }

      final eventArray = <Termin>[];
      if (events != null) {
        for (Event e in events) {
          if (e != null) {
            if(e.allDay){
              if(e.end.difference(lastMidnight).inHours  > 12) {
                eventArray.add(
                    Termin(lastMidnight, nextMidnight, e.title, e.eventId));
              }
            } else {
              eventArray.add(Termin(e.start, e.end, e.title, e.eventId));
            }
          }
        }
      }

      eventArray.sort();
      setState(() {
        _eventArray = eventArray;
        _calenderFetcher = new Timer(calendarRefreshTime, _retrieveCalendars);
      });
    } on PlatformException catch (e) {
      log("failed to fetch events", error: e);
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
    final  screenWidth = MediaQuery.of(context).size.width;
    final  screenHeight = MediaQuery.of(context).size.height;

    final fontScale = (screenHeight < (screenWidth)?screenHeight:screenWidth)*0.025;

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

    final time = DateFormat.Hms().format(_now);



    final infoText = DefaultTextStyle(
      style: TextStyle(color: customTheme.primaryColor, fontSize: fontScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat.yMMMd().format(_now)),
        ],
      ),
    );

    final clockFace = <Widget>[];

    if (_eventArray != null) {
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

      final hourEvents = _eventArray
          .where((t) => t.includedIn(start, end) && !t.isAllDayEvent);

      //outer ring
      for (Termin t in hourEvents) {
        clockFace.add(Arc(
          color: pickColor(t.id + "1"),
          scale: 1,
          thickness: 0.08,
          angleRadians:
              math.max(0, t.lengthIn(start, end).inMinutes) * radiansPerSecond,
          angleStart: t.getRelativeStart(start).hour * radiansPerHour +
              t.getRelativeStart(start).minute * radiansPerSecond,
          text: "${t.title} ${DateFormat.Hm().format(t.start)}-${DateFormat.Hm().format(t.end)}",
        ));
      }

      if (widget.model.innerCircle) {
        final minuteEvents = _eventArray.where((t) =>
        t.includedIn(
            lastHour, lastHour.add(Duration(minutes: 59, seconds: 59))) &&
            !t.isAllDayEvent);

        //inner ring
        for (Termin t in minuteEvents) {
          clockFace.add(Arc(
            color: pickColor(t.id + "1"),
            scale: 0.75,
            thickness: 0.085,
            angleRadians:
            t
                .lengthIn(lastHour, nextHour)
                .inMinutes * radiansPerTick,
            angleStart: t
                .getRelativeStart(lastHour)
                .minute * radiansPerTick,
            text: t.title,
          ));
        }
      }
    }

    final allDayEvents = _eventArray?.where((t) => t.isAllDayEvent)?.toList();

    return Semantics.fromProperties(
        properties: SemanticsProperties(
          label: 'Analog clock with time $time',
          value: time,
        ),
        child: Container(
          color: customTheme.backgroundColor,
          child: Stack(children: [
            Container(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  child: Stack(
                    children: [
                      RepaintBoundary(
                        child: ClockFace(
                          primaryColor: customTheme.primaryColor,
                          secondaryColor: customTheme.accentColor,
                          second:_now.second,
                          scale: 0.87,
                          thickness: 1,
                        ),
                      ),
                      RepaintBoundary(
                        child: Stack(
                          children: clockFace,
                        ),
                      ),
                      DrawnHand(
                        //hour
                        color: customTheme.primaryColor,
                        size: 0.6,
                        thickness: 3,
                        angleRadians: _now.hour * radiansPerHour +
                            (_now.minute / 60) * radiansPerHour,
                      ),
                      DrawnHand(
                        //minutes
                        color: customTheme.highlightColor,
                        thickness: 3,
                        size: 0.8,
                        angleRadians: _now.minute * radiansPerTick,
                      ),
//                      RepaintBoundary(
//                        child: DrawnHand(
//                          //seconds
//                          color: customTheme.accentColor,
//                          thickness: 2,
//                          size: 0.85,
//                          angleRadians: _now.second * radiansPerTick,
//                        ),
//                      ),
//                      Disk(
//                        color: customTheme.primaryColor,
//                        scale: 0.04,
//                        thickness: 2,
//                        angleRadians: 2 * math.pi,
//                        angleStart: 0,
//                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                  width: screenWidth*0.20,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: Container(width: 0,height: 0,),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left:5,top: 10),
                          child: infoText,
                        ),
                        (widget.model.allDay && allDayEvents != null && allDayEvents.length > 0)
                            ? Column(children: [
//                                Padding(
//                                  padding: const EdgeInsets.only(top: 5),
//                                  child: Text("All Day Events",style: TextStyle(fontSize: fontScale,),),
//                                ),
                                Divider(thickness: 1.5,),
                                ListView.separated(
                                  itemBuilder: (context, index) {
                                    return Container(
                                        decoration: BoxDecoration(
                                          color: pickColor(allDayEvents[index].id),
                                          borderRadius: BorderRadius.all(const Radius.circular(30.0))
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            allDayEvents[index].title,
                                            style: TextStyle(
                                              fontSize: fontScale * 0.85,
                                              color: Colors.grey[800],
                                            ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ),
                                    );
                                  },
                                  itemCount: allDayEvents.length,
                                  separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 4,),
                                  shrinkWrap: true,
                                )
                              ])
                            : Container(
                                height: 0,
                                width: 0,
                              ),
                      ],
                    ),
                  ),
                ),
            ),
//            Positioned(
//              //added info
//              left: 0,
//              bottom: 0,
//              child: Padding(
//                padding: const EdgeInsets.all(15),
//                child: infoText,
//              ),
//            ),
          ]),
        ));
  }
}
