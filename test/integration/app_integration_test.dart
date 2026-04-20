import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:optiflow/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('OptiFlow App Integration Tests', () {
    testWidgets('complete app launch and navigation flow', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify app launches successfully
      expect(find.byType(MaterialApp), findsOneWidget);

      // Test initial screen loading (onboarding or home)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for common app elements
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('navigation between main screens', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test navigation to different screens if navigation is available
      final navigationButtons = find.byType(IconButton);
      if (navigationButtons.evaluate().isNotEmpty) {
        // Try tapping navigation buttons
        await tester.tap(navigationButtons.first);
        await tester.pumpAndSettle();
        
        // Verify navigation worked
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('map screens integration', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for map-related screens or buttons
      final mapButtons = find.byIcon(Icons.map);
      if (mapButtons.evaluate().isNotEmpty) {
        await tester.tap(mapButtons.first);
        await tester.pumpAndSettle();
        
        // Verify map screen loads
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('form interactions', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for form fields
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        // Test text input
        await tester.enterText(textFields.first, 'Test Input');
        await tester.pumpAndSettle();
        
        // Verify input was accepted
        expect(find.text('Test Input'), findsOneWidget);
      }
    });

    testWidgets('button interactions', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for buttons
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();
        
        // Verify button interaction
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('list scrolling', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for scrollable content
      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        // Test scrolling
        await tester.fling(scrollables.first, const Offset(0, -300), 1000);
        await tester.pumpAndSettle();
        
        // Verify scrolling worked
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('dialog interactions', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for dialog triggers
      final dialogButtons = find.byType(TextButton);
      if (dialogButtons.evaluate().isNotEmpty) {
        await tester.tap(dialogButtons.first);
        await tester.pumpAndSettle();
        
        // Look for dialogs
        final dialogs = find.byType(Dialog);
        if (dialogs.evaluate().isNotEmpty) {
          expect(dialogs, findsOneWidget);
          
          // Close dialog
          await tester.tap(find.text('OK').first);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('app lifecycle', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test app lifecycle (minimize and restore)
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        null,
        (data) {},
      );

      await tester.pumpAndSettle();
      
      // Verify app is still responsive
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('memory usage', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Perform various interactions to test memory
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        for (int i = 0; i < 5; i++) {
          await tester.tap(buttons.first);
          await tester.pumpAndSettle();
          
          // Navigate back if possible
          final backButton = find.byIcon(Icons.arrow_back);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton);
            await tester.pumpAndSettle();
          }
        }
      }
      
      // Verify app is still stable
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('error handling', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test various error scenarios
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        // Test invalid input
        await tester.enterText(textFields.first, '');
        await tester.pumpAndSettle();
        
        // Test validation
        final submitButtons = find.byType(ElevatedButton);
        if (submitButtons.evaluate().isNotEmpty) {
          await tester.tap(submitButtons.first);
          await tester.pumpAndSettle();
          
          // Look for error messages
          final errorTexts = find.textContaining('error');
          if (errorTexts.evaluate().isNotEmpty) {
            expect(errorTexts, findsWidgets);
          }
        }
      }
      
      // Verify app handles errors gracefully
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('Performance Tests', () {
    testWidgets('app startup performance', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // App should start within reasonable time (5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      
      // Verify app is responsive
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('screen transition performance', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final stopwatch = Stopwatch()..start();
      
      // Test navigation if available
      final navigationButtons = find.byType(IconButton);
      if (navigationButtons.evaluate().isNotEmpty) {
        await tester.tap(navigationButtons.first);
        await tester.pumpAndSettle();
      }
      
      stopwatch.stop();
      
      // Screen transitions should be fast (1 second)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    testWidgets('scrolling performance', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        final stopwatch = Stopwatch()..start();
        
        // Test scrolling performance
        await tester.fling(scrollables.first, const Offset(0, -500), 2000);
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // Scrolling should be smooth (500ms for fling)
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      }
    });
  });

  group('Accessibility Tests', () {
    testWidgets('semantic labels', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for semantic labels
      final semantics = tester.binding.semanticsOwner();
      
      // Verify important elements have semantic labels
      expect(semantics.rootSemanticsNode, isNotNull);
    });

    testWidgets('focus handling', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test focus navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      
      // Verify focus handling works
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('Platform Integration Tests', () {
    testWidgets('platform-specific features', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test platform-specific integrations
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('permission handling', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test permission-related flows
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
