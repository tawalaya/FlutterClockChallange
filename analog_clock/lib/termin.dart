import 'dart:developer';

class Termin implements Comparable<Termin> {
  final DateTime start;
  final DateTime end;
  final String title;

  Termin(this.start, this.end, this.title) {
//    log("Termin(${this.start.hour}:${this.start.minute} - ${this.end.hour}:${this.end.minute}}");
    assert(this.start.isBefore(this.end));
  }

  Duration get length => this.end.difference(this.start);

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
