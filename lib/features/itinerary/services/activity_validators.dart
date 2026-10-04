import 'package:flutter/material.dart';

class ActivityValidators {
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter an activity title.';
    }
    return null;
  }

  static String? validatePlaceName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a place name.';
    }
    return null;
  }

  static String? validateDate(DateTime? value) {
    if (value == null) {
      return 'Choose an activity date.';
    }
    return null;
  }

  static String? validateTimes(TimeOfDay? startTime, TimeOfDay? endTime) {
    if (startTime == null) {
      return 'Choose a start time.';
    }
    if (endTime == null) {
      return 'Choose an end time.';
    }
    if (timeOfDayToMinutes(endTime) < timeOfDayToMinutes(startTime)) {
      return 'End time cannot be earlier than the start time.';
    }
    return null;
  }

  static String? validateCoordinate(
    String? value, {
    required double minimum,
    required double maximum,
    required String label,
  }) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return null;
    }
    final coordinate = double.tryParse(input);
    if (coordinate == null || coordinate < minimum || coordinate > maximum) {
      return 'Enter a valid $label.';
    }
    return null;
  }

  static int timeOfDayToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  static String serializeTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static TimeOfDay? parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
