/*
 * Copyright (c) 2020 Sebastian Werner & Andreas Salzmann, All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
import 'dart:developer';

class Termin implements Comparable<Termin> {
  final DateTime start;
  final DateTime end;
  final String title;
  final String id;

  Termin(this.start, this.end, this.title,this.id) {
//    log("Termin(${this.start.hour}:${this.start.minute} - ${this.end.hour}:${this.end.minute}}");
    assert(this.start.isBefore(this.end));
  }

  bool get isAllDayEvent => this.end.difference(this.start).inDays >= 1;

  Duration get length => this.end.difference(this.start);

  Duration lengthIn(DateTime start,DateTime end) {
    DateTime s;
    if(this.start.isBefore(start)){
      s = start;
    } else {
      s = this.start;
    }

    DateTime e;
    if(this.end.isAfter(end)){
      e = end;
    } else {
      e = this.end;
    }

    return e.difference(s);
  }

  DateTime getRelativeStart(DateTime reference) {
    if(this.start.isBefore(reference)){
      return reference;
    } else {
      return this.start;
    }
  }

  @override
  int compareTo(Termin other) {
    /*
      this:   |----|
      others:
      1:   |---|
      -1:         |---|
      2:|---|
      -2:             |---|
      0:      |----|

    */

    if (this.start == other.start && this.end == other.end) {
      return 0;
    }
    if (this.start.isBefore(other.start)) {
      if (this.end.isAfter(other.start)) {
        //other starts within this termin (overlapping)
        return -1;
      } else {
        return -2;
      }
    } else {
      if (other.end.isBefore(this.start)) {
        return 2;
      } else {
        //other is started before this but overlapps
        return 1;
      }
    }
  }

  bool isBefore(DateTime deadline) => this.start.isBefore(deadline);

  bool includedIn(DateTime start, end) {
    if (this.start == start && this.end == end) {
      return true;
    }
    if (this.start.isBefore(start)) {
      if (this.end.isAfter(start)) {
        return true;
      } else {
        return false;
      }
    } else {
      if (end.isBefore(this.start)) {
        return false;
      } else {
        return true;
      }
    }
  }
}
