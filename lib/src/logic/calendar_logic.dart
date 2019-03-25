//  Copyright (c) 2019 Aleksander Woźniak
//  Licensed under Apache License v2.0

import 'package:date_utils/date_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../table_calendar.dart';

const double _dxMax = 1.2;
const double _dxMin = -1.2;

class CalendarLogic {
  DateTime get selectedDate => _selectedDate;
  set selectedDate(DateTime value) {
    if (calendarFormat == CalendarFormat.month) {
      if (_isExtraDayBefore(value)) {
        _decrementPage();
      } else if (_isExtraDayAfter(value)) {
        _incrementPage();
      }
    }

    _selectedDate = value;
    _focusedDate = value;

    if (calendarFormat != CalendarFormat.twoWeeks) {
      _visibleDays.value = _getVisibleDays();
    }
  }

  int get pageId => _pageId;
  double get dx => _dx;
  CalendarFormat get calendarFormat => _calendarFormat.value;
  List<DateTime> get visibleDays => _visibleDays.value;
  String get headerText => DateFormat.yMMMM().format(_focusedDate);
  String get formatButtonText => _availableCalendarFormats[_nextFormat()];

  DateTime _focusedDate;
  DateTime _selectedDate;
  StartingDayOfWeek _startingDayOfWeek;
  ValueNotifier<CalendarFormat> _calendarFormat;
  ValueNotifier<List<DateTime>> _visibleDays;
  DateTime _previousFirstDay;
  DateTime _previousLastDay;
  Map<CalendarFormat, String> _availableCalendarFormats;
  int _pageId;
  double _dx;

  CalendarLogic(
    this._availableCalendarFormats,
    this._startingDayOfWeek, {
    DateTime initialDate,
    CalendarFormat initialFormat,
    OnFormatChanged onFormatChanged,
    OnVisibleDaysChanged onVisibleDaysChanged,
    bool includeInvisibleDays = false,
  })  : _pageId = 0,
        _dx = 0 {
    final now = DateTime.now();
    _focusedDate = initialDate ?? DateTime(now.year, now.month, now.day);
    _selectedDate = _focusedDate;
    _calendarFormat = ValueNotifier(initialFormat);
    _visibleDays = ValueNotifier(_getVisibleDays());
    _previousFirstDay = _visibleDays.value.first;
    _previousLastDay = _visibleDays.value.last;

    _calendarFormat.addListener(() {
      _visibleDays.value = _getVisibleDays();

      if (onFormatChanged != null) {
        onFormatChanged(_calendarFormat.value);
      }
    });

    if (onVisibleDaysChanged != null) {
      _visibleDays.addListener(() {
        if (!Utils.isSameDay(_visibleDays.value.first, _previousFirstDay) || !Utils.isSameDay(_visibleDays.value.last, _previousLastDay)) {
          _previousFirstDay = _visibleDays.value.first;
          _previousLastDay = _visibleDays.value.last;
          onVisibleDaysChanged(_getFirstDay(includeInvisibleDays), _getLastDay(includeInvisibleDays));
        }
      });
    }
  }

  void dispose() {
    _calendarFormat.dispose();
    _visibleDays.dispose();
  }

  CalendarFormat _nextFormat() {
    final formats = _availableCalendarFormats.keys.toList();
    int id = formats.indexOf(_calendarFormat.value);
    id = (id + 1) % formats.length;

    return formats[id];
  }

  void toggleCalendarFormat() {
    _calendarFormat.value = _nextFormat();
  }

  void swipeCalendarFormat(bool isSwipeUp) {
    final formats = _availableCalendarFormats.keys.toList();
    int id = formats.indexOf(_calendarFormat.value);

    // Order of CalendarFormats must be from biggest to smallest,
    // eg.: [month, twoWeeks, week]
    if (isSwipeUp) {
      id = _clamp(0, formats.length - 1, id + 1);
    } else {
      id = _clamp(0, formats.length - 1, id - 1);
    }
    _calendarFormat.value = formats[id];
  }

  void selectPrevious() {
    if (calendarFormat == CalendarFormat.month) {
      _selectPreviousMonth();
    } else if (calendarFormat == CalendarFormat.twoWeeks) {
      _selectPreviousTwoWeeks();
    } else {
      _selectPreviousWeek();
    }

    _visibleDays.value = _getVisibleDays();
    _decrementPage();
  }

  void selectNext() {
    if (calendarFormat == CalendarFormat.month) {
      _selectNextMonth();
    } else if (calendarFormat == CalendarFormat.twoWeeks) {
      _selectNextTwoWeeks();
    } else {
      _selectNextWeek();
    }

    _visibleDays.value = _getVisibleDays();
    _incrementPage();
  }

  void _selectPreviousMonth() {
    _focusedDate = Utils.previousMonth(_focusedDate);
  }

  void _selectNextMonth() {
    _focusedDate = Utils.nextMonth(_focusedDate);
  }

  void _selectPreviousTwoWeeks() {
    if (_visibleDays.value.take(7).contains(_focusedDate)) {
      // in top row
      _focusedDate = Utils.previousWeek(_focusedDate);
    } else {
      // in bottom row OR not visible
      _focusedDate = Utils.previousWeek(_focusedDate.subtract(const Duration(days: 7)));
    }
  }

  void _selectNextTwoWeeks() {
    if (!_visibleDays.value.skip(7).contains(_focusedDate)) {
      // not in bottom row [eg: in top row OR not visible]
      _focusedDate = Utils.nextWeek(_focusedDate);
    }
  }

  void _selectPreviousWeek() {
    _focusedDate = Utils.previousWeek(_focusedDate);
  }

  void _selectNextWeek() {
    _focusedDate = Utils.nextWeek(_focusedDate);
  }

  DateTime _getFirstDay(bool includeInvisible) {
    if (_calendarFormat.value == CalendarFormat.month && !includeInvisible) {
      return Utils.firstDayOfMonth(_focusedDate);
    } else {
      return _visibleDays.value.first;
    }
  }

  DateTime _getLastDay(bool includeInvisible) {
    if (_calendarFormat.value == CalendarFormat.month && !includeInvisible) {
      var last = Utils.lastDayOfMonth(_focusedDate);
      if (last.hour == 23) {
        last = last.add(Duration(hours: 1));
      }
      return last;
    } else {
      return _visibleDays.value.last;
    }
  }

  List<DateTime> _getVisibleDays() {
    if (calendarFormat == CalendarFormat.month) {
      return _daysInMonth(_focusedDate);
    } else if (calendarFormat == CalendarFormat.twoWeeks) {
      return _daysInWeek(_focusedDate)
        ..addAll(_daysInWeek(
          _focusedDate.add(const Duration(days: 7)),
        ));
    } else {
      return _daysInWeek(_focusedDate);
    }
  }

  void _decrementPage() {
    _pageId--;
    _dx = _dxMin;
  }

  void _incrementPage() {
    _pageId++;
    _dx = _dxMax;
  }

  List<DateTime> _daysInMonth(DateTime month) {
    final first = Utils.firstDayOfMonth(month);
    final daysBefore = _startingDayOfWeek == StartingDayOfWeek.sunday ? first.weekday % 7 : first.weekday - 1;
    var firstToDisplay = first.subtract(Duration(days: daysBefore));

    if (firstToDisplay.hour == 23) {
      firstToDisplay = firstToDisplay.add(Duration(hours: 1));
    }

    var last = Utils.lastDayOfMonth(month);

    if (last.hour == 23) {
      last = last.add(Duration(hours: 1));
    }

    var daysAfter = 7 - last.weekday;

    if (_startingDayOfWeek == StartingDayOfWeek.sunday) {
      // If the last day is Sunday (7) the entire week must be rendered
      if (daysAfter == 0) {
        daysAfter = 7;
      }
    } else {
      daysAfter++;
    }

    var lastToDisplay = last.add(Duration(days: daysAfter));

    if (lastToDisplay.hour == 1) {
      lastToDisplay = lastToDisplay.subtract(Duration(hours: 1));
    }

    return Utils.daysInRange(firstToDisplay, lastToDisplay).toList();
  }

  List<DateTime> _daysInWeek(DateTime week) {
    final first = _firstDayOfWeek(week);
    final last = _lastDayOfWeek(week);

    final days = Utils.daysInRange(first, last);
    return days.map((day) => DateTime(day.year, day.month, day.day)).toList();
  }

  DateTime _firstDayOfWeek(DateTime day) {
    day = DateTime.utc(day.year, day.month, day.day, 12);

    final decreaseNum = _startingDayOfWeek == StartingDayOfWeek.sunday ? day.weekday % 7 : day.weekday - 1;
    return day.subtract(Duration(days: decreaseNum));
  }

  DateTime _lastDayOfWeek(DateTime day) {
    day = DateTime.utc(day.year, day.month, day.day, 12);

    final increaseNum = _startingDayOfWeek == StartingDayOfWeek.sunday ? day.weekday % 7 : day.weekday - 1;
    return day.add(Duration(days: 7 - increaseNum));
  }

  bool isSelected(DateTime day) {
    return Utils.isSameDay(day, selectedDate);
  }

  bool isToday(DateTime day) {
    return Utils.isSameDay(day, DateTime.now());
  }

  bool isWeekend(DateTime day) {
    return day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
  }

  bool isExtraDay(DateTime day) {
    return _isExtraDayBefore(day) || _isExtraDayAfter(day);
  }

  bool _isExtraDayBefore(DateTime day) {
    return day.month < _focusedDate.month;
  }

  bool _isExtraDayAfter(DateTime day) {
    return day.month > _focusedDate.month;
  }

  int _clamp(int min, int max, int value) {
    if (value > max) {
      return max;
    } else if (value < min) {
      return min;
    } else {
      return value;
    }
  }
}
