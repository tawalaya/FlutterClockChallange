// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// This is the model that contains the customization options for the clock.
///
/// It is a [ChangeNotifier], so use [ChangeNotifier.addListener] to listen to
/// changes to the model. Be sure to call [ChangeNotifier.removeListener] in
/// your `dispose` method.
///
/// Contestants: Do not edit this.
class ClockModel extends ChangeNotifier {

  bool _pieMode = true;
  get pieMode => _pieMode;
  set pieMode(bool pieMode) {
    if (_pieMode != pieMode) {
      _pieMode = pieMode;
      notifyListeners();
    }
  }

  bool _allDay = true;
  get allDay => _allDay;
  set allDay(bool flag) {
    if (_allDay != flag) {
      _allDay = flag;
      notifyListeners();
    }
  }

  List<String> _calenderIds = new List();
  get calenderIds => _calenderIds;
  set calenderIds(List<String> ids){
    if(_calenderIds != ids){
      _calenderIds = ids;
      notifyListeners();
    }
  }

  add(String id){
    if(!_calenderIds.contains(id)){
      _calenderIds.add(id);
      notifyListeners();
    }
  }

  bool isActive(String id) => _calenderIds?.contains(id);

  @override
  bool operator ==(other) {
    return other is ClockModel && other._pieMode == _pieMode && _calenderIds == other._calenderIds;
  }

  void remove(String id) {
    _calenderIds.remove(id);
    notifyListeners();
  }


}

/// Removes the enum type and returns the value as a String.
String enumToString(Object e) => e.toString().split('.').last;
