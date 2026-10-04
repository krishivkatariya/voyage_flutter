class TripValidators {
  static String? validateTripName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a trip name.';
    }
    return null;
  }

  static String? validateDestination(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a destination.';
    }
    return null;
  }

  static String? validateDates(DateTime? startDate, DateTime? endDate) {
    if (startDate == null) {
      return 'Choose a start date.';
    }
    if (endDate == null) {
      return 'Choose an end date.';
    }
    if (_dateOnly(endDate).isBefore(_dateOnly(startDate))) {
      return 'End date cannot be before the start date.';
    }
    return null;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
