// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'customizer.dart';
import 'model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'analog_clock.dart';

void main() {

  if (!kIsWeb && Platform.isMacOS) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }

  runApp(ClockCustomizer((ClockModel model) => AnalogClock(model)));
}
