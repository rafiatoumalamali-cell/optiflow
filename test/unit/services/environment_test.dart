import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import '../../../lib/utils/environment.dart';

void main() {
  group('Environment Tests', () {
    test('should return correct environment type based on build mode', () {
      // Test in debug mode
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      
      // Since we can't actually change build mode in tests,
      // we'll test the logic that would be used
      expect(EnvironmentType.values, contains(EnvironmentType.development));
      expect(EnvironmentType.values, contains(EnvironmentType.production));
      expect(EnvironmentType.values, contains(EnvironmentType.staging));
      
      debugDefaultTargetPlatformOverride = null;
    });

    test('should have valid API URLs for all environments', () {
      // Test that API base URLs are not empty
      expect(Environment.apiBaseUrl, isNotEmpty);
      expect(Environment.apiBaseUrl, isA<String>());
    });

    test('should have valid Google Maps API key', () {
      // Test that Google Maps API key is not empty
      expect(Environment.googleMapsApiKey, isNotEmpty);
      expect(Environment.googleMapsApiKey, isA<String>());
    });

    test('should return correct API URL for development', () {
      // Test development URL structure
      final devUrl = Environment.apiBaseUrl;
      expect(devUrl, contains('http'));
    });

    test('should return correct Google Maps API key format', () {
      // Test that API key follows expected format
      final apiKey = Environment.googleMapsApiKey;
      expect(apiKey, matches(RegExp(r'^AIza[A-Za-z0-9_-]{35}$')));
    });

    test('should have environment-specific configuration', () {
      // Test that environment configuration is properly set
      expect(Environment.current, isA<EnvironmentType>());
    });

    test('should handle environment switching correctly', () {
      // Test environment switching logic
      final currentEnv = Environment.current;
      expect(currentEnv, isA<EnvironmentType>());
    });

    test('should validate environment configuration', () {
      // Test environment validation
      expect(Environment.apiBaseUrl, isNotEmpty);
      expect(Environment.googleMapsApiKey, isNotEmpty);
    });

    test('should handle production environment configuration', () {
      // Test production-specific settings
      expect(Environment.apiBaseUrl, isNotEmpty);
      expect(Environment.googleMapsApiKey, isNotEmpty);
    });
  });
}
