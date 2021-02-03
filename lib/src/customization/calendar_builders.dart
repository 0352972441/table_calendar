// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

part of table_calendar;

/// Builder signature for a single event marker. Contains `date` and a single `event` associated with that `date`.
typedef SingleMarkerBuilder<T> = Widget Function(
    BuildContext context, DateTime date, T event);

typedef MarkerBuilder<T> = Widget Function(
    BuildContext context, DateTime date, List<T> events);

typedef HighlightBuilder = Widget Function(
    BuildContext context, DateTime date, bool isWithinRange);

class CalendarBuilders<T> {
  final FocusedDayBuilder prioritizedBuilder;
  final FocusedDayBuilder todayBuilder;
  final FocusedDayBuilder selectedBuilder;
  final FocusedDayBuilder rangeStartBuilder;
  final FocusedDayBuilder rangeEndBuilder;
  final FocusedDayBuilder withinRangeBuilder;
  final FocusedDayBuilder outsideBuilder;
  final FocusedDayBuilder disabledBuilder;
  final FocusedDayBuilder holidayBuilder;
  final FocusedDayBuilder defaultBuilder;

  final HighlightBuilder rangeHighlightBuilder;

  final SingleMarkerBuilder<T> singleMarkerBuilder;
  final MarkerBuilder<T> markerBuilder;

  final DayBuilder dowBuilder;

  const CalendarBuilders({
    this.prioritizedBuilder,
    this.todayBuilder,
    this.selectedBuilder,
    this.rangeStartBuilder,
    this.rangeEndBuilder,
    this.withinRangeBuilder,
    this.outsideBuilder,
    this.disabledBuilder,
    this.holidayBuilder,
    this.defaultBuilder,
    this.rangeHighlightBuilder,
    this.singleMarkerBuilder,
    this.markerBuilder,
    this.dowBuilder,
  });
}
