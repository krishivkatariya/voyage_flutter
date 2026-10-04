class MemberValidators {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter an email address.';
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Normalizes an email address so it can be stored in and queried from the
  /// `userDirectory/{userId}` lookup collection (`emailLowercase` field).
  static String normalizeEmail(String? value) {
    return (value ?? '').trim().toLowerCase();
  }
}
