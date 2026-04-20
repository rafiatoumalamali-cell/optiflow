class DeveloperService {
  // Authorized developer phone numbers
  static const List<String> _developers = [
    '+233503836061',
  ];

  static bool isDeveloper(String? phoneNumber) {
    if (phoneNumber == null) return false;
    String normalized = phoneNumber.trim().replaceAll(' ', '');
    return _developers.contains(normalized);
  }
}
