import 'package:flutter/widgets.dart';

const months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
DateTime calendarDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);
String dayLabel(DateTime date) =>
    '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
String kcal(double value) => value.round().toString();
String initials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return words.take(2).map((w) => w.characters.first.toUpperCase()).join();
}
