import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Onboarding ---
  static Future<void> setOnboardingSeen(bool seen) async => await _prefs.setBool('onboardingSeen', seen);
  static bool get onboardingSeen => _prefs.getBool('onboardingSeen') ?? false;

  // --- Auth ---
  static Future<void> setIsLoggedIn(bool loggedIn) async => await _prefs.setBool('isLoggedIn', loggedIn);
  static bool get isLoggedIn => _prefs.getBool('isLoggedIn') ?? false;

  static Future<void> setUserPhone(String phone) async => await _prefs.setString('userPhone', phone);
  static String? get userPhone => _prefs.getString('userPhone');

  static Future<void> setUserEmail(String email) async => await _prefs.setString('userEmail', email);
  static String? get userEmail => _prefs.getString('userEmail');

  static Future<void> setUserRole(String role) async => await _prefs.setString('userRole', role);
  static String? get userRole => _prefs.getString('userRole');

  // --- Business Setup ---
  static Future<void> setIsBusinessSetupComplete(bool complete) async => await _prefs.setBool('isBusinessSetupComplete', complete);
  static bool get isBusinessSetupComplete => _prefs.getBool('isBusinessSetupComplete') ?? false;

  static Future<void> setBusinessId(String id) async => await _prefs.setString('businessId', id);
  static String? get businessId => _prefs.getString('businessId');

  static Future<void> setBusinessName(String name) async => await _prefs.setString('businessName', name);
  static String? get businessName => _prefs.getString('businessName');

  static Future<void> setBusinessCountry(String country) async => await _prefs.setString('businessCountry', country);
  static String? get businessCountry => _prefs.getString('businessCountry');

  static Future<void> setBusinessCurrency(String currency) async => await _prefs.setString('businessCurrency', currency);
  static String? get businessCurrency => _prefs.getString('businessCurrency');

  static Future<void> setBusinessCities(List<String> cities) async => await _prefs.setStringList('businessCities', cities);
  static List<String>? get businessCities => _prefs.getStringList('businessCities');

  // Clear all (Logout)
  static Future<void> clear() async => await _prefs.clear();
}
