import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:optiflow/providers/auth_provider.dart';

import '../mocks/mock_firestore_service.dart';

@GenerateMocks([MockFirestoreService])
void main() {
  group('AuthProvider Tests', () {
    late AuthProvider authProvider;
    late MockFirestoreService mockFirestoreService;

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      authProvider = AuthProvider(firestoreService: mockFirestoreService);
    });

    test('should initialize with empty user state', () {
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.isLoading, isFalse);
    });

    test('should handle login state correctly', () async {
      // Mock successful login
      when(mockFirestoreService.signInWithEmailAndPassword(any, any))
          .thenAnswer((_) async => Future.value());

      await authProvider.signIn('test@example.com', 'password123');

      verify(mockFirestoreService.signInWithEmailAndPassword('test@example.com', 'password123')).called(1);
    });

    test('should handle logout correctly', () async {
      // Mock successful logout
      when(mockFirestoreService.signOut()).thenAnswer((_) async => Future.value());

      await authProvider.signOut();

      verify(mockFirestoreService.signOut()).called(1);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isLoggedIn, isFalse);
    });

    test('should handle password reset correctly', () async {
      // Mock successful password reset
      when(mockFirestoreService.sendPasswordResetEmail(any))
          .thenAnswer((_) async => Future.value());

      await authProvider.resetPassword('test@example.com');

      verify(mockFirestoreService.sendPasswordResetEmail('test@example.com')).called(1);
    });

    test('should handle user registration correctly', () async {
      // Mock successful registration
      when(mockFirestoreService.createUserWithEmailAndPassword(any, any, any))
          .thenAnswer((_) async => Future.value());

      await authProvider.signUp('test@example.com', 'password123', 'Test User');

      verify(mockFirestoreService.createUserWithEmailAndPassword('test@example.com', 'password123', 'Test User')).called(1);
    });

    test('should handle loading states correctly', () {
      // Test loading state management
      authProvider.setLoading(true);
      expect(authProvider.isLoading, isTrue);

      authProvider.setLoading(false);
      expect(authProvider.isLoading, isFalse);
    });

    test('should handle error states correctly', () {
      // Test error handling
      final error = 'Test error message';
      authProvider.setError(error);
      
      expect(authProvider.errorMessage, equals(error));
    });

    test('should validate email correctly', () {
      // Test email validation
      expect(authProvider.isValidEmail('test@example.com'), isTrue);
      expect(authProvider.isValidEmail('invalid-email'), isFalse);
      expect(authProvider.isValidEmail(''), isFalse);
    });

    test('should validate password correctly', () {
      // Test password validation
      expect(authProvider.isValidPassword('password123'), isTrue);
      expect(authProvider.isValidPassword('123'), isFalse); // Too short
      expect(authProvider.isValidPassword(''), isFalse);
    });
  });
}
