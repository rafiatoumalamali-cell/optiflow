class Validators {
  /// Validates international phone numbers with optional leading plus.
  ///
  /// Accepts between 10 and 15 digits total, including country code.
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[0-9]{10,15}$').hasMatch(phone);
  }

  /// Validates a basic email address pattern.
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Validates passwords with a minimum length.
  static bool isValidPassword(String password, {int minLength = 6}) {
    return password.trim().length >= minLength;
  }
}
