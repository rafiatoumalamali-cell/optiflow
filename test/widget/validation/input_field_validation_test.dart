import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optiflow/utils/input_validation.dart';
import 'package:optiflow/widgets/common/validated_text_field.dart';

void main() {
  group('Input Field Validation Widget Tests', () {
    testWidgets('should validate email field in real-time', (WidgetTester tester) async {
      String? emailError;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValidatedTextField(
              label: 'Email',
              validationType: ValidationType.email,
              onChanged: (value) {
                emailError = InputValidation.getEmailError(value);
              },
            ),
          ),
        ),
      );

      // Find the text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Test valid email
      await tester.enterText(textField, 'test@example.com');
      await tester.pump();
      
      expect(emailError, isNull);

      // Test invalid email
      await tester.enterText(textField, 'invalid-email');
      await tester.pump();
      
      expect(emailError, isNotNull);
      expect(emailError, equals('Please enter a valid email address'));

      // Test empty email
      await tester.enterText(textField, '');
      await tester.pump();
      
      expect(emailError, equals('Email is required'));
    });

    testWidgets('should validate phone field in real-time', (WidgetTester tester) async {
      String? phoneError;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValidatedTextField(
              label: 'Phone',
              validationType: ValidationType.phone,
              onChanged: (value) {
                phoneError = InputValidation.getPhoneError(value);
              },
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Test valid phone
      await tester.enterText(textField, '+22720123456');
      await tester.pump();
      
      expect(phoneError, isNull);

      // Test invalid phone
      await tester.enterText(textField, '123');
      await tester.pump();
      
      expect(phoneError, isNotNull);
      expect(phoneError, equals('Please enter a valid phone number'));

      // Test empty phone
      await tester.enterText(textField, '');
      await tester.pump();
      
      expect(phoneError, equals('Phone number is required'));
    });

    testWidgets('should validate password field with strength indicator', (WidgetTester tester) async {
      String? passwordError;
      int passwordStrength = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValidatedTextField(
              label: 'Password',
              validationType: ValidationType.password,
              obscureText: true,
              onChanged: (value) {
                passwordError = InputValidation.getPasswordError(value);
                passwordStrength = InputValidation.getPasswordStrength(value);
              },
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Test weak password
      await tester.enterText(textField, 'password');
      await tester.pump();
      
      expect(passwordError, isNotNull);
      expect(passwordStrength, equals(2)); // Has lowercase and length

      // Test strong password
      await tester.enterText(textField, 'StrongP@ssw0rd');
      await tester.pump();
      
      expect(passwordError, isNull);
      expect(passwordStrength, equals(5)); // Perfect strength

      // Test empty password
      await tester.enterText(textField, '');
      await tester.pump();
      
      expect(passwordError, equals('Password is required'));
      expect(passwordStrength, equals(0));
    });

    testWidgets('should validate name field with formatting', (WidgetTester tester) async {
      String? nameError;
      String formattedName = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValidatedTextField(
              label: 'Name',
              validationType: ValidationType.name,
              onChanged: (value) {
                nameError = InputValidation.getNameError(value);
                formattedName = InputValidation.formatName(value);
              },
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Test valid name
      await tester.enterText(textField, 'john doe');
      await tester.pump();
      
      expect(nameError, isNull);
      expect(formattedName, equals('John Doe'));

      // Test invalid name (too short)
      await tester.enterText(textField, 'J');
      await tester.pump();
      
      expect(nameError, isNotNull);
      expect(nameError, equals('Name must be at least 2 characters'));

      // Test name with special characters
      await tester.enterText(textField, 'john@doe');
      await tester.pump();
      
      expect(nameError, isNotNull);
      expect(nameError, equals('Name can only contain letters, spaces, hyphens, and apostrophes'));
    });

    testWidgets('should validate numeric fields (weight, distance, price)', (WidgetTester tester) async {
      String? weightError;
      String? distanceError;
      String? priceError;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ValidatedTextField(
                  label: 'Weight',
                  validationType: ValidationType.weight,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    weightError = InputValidation.getWeightError(value);
                  },
                ),
                ValidatedTextField(
                  label: 'Distance',
                  validationType: ValidationType.distance,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    distanceError = InputValidation.getDistanceError(value);
                  },
                ),
                ValidatedTextField(
                  label: 'Price',
                  validationType: ValidationType.price,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    priceError = InputValidation.getPriceError(value);
                  },
                ),
              ],
            ),
          ),
        ),
      );

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(3));

      // Test weight field
      await tester.enterText(textFields.at(0), '10.5');
      await tester.pump();
      expect(weightError, isNull);

      await tester.enterText(textFields.at(0), '0');
      await tester.pump();
      expect(weightError, equals('Weight must be greater than 0'));

      // Test distance field
      await tester.enterText(textFields.at(1), '25.3');
      await tester.pump();
      expect(distanceError, isNull);

      await tester.enterText(textFields.at(1), '-5');
      await tester.pump();
      expect(distanceError, equals('Distance must be greater than 0'));

      // Test price field
      await tester.enterText(textFields.at(2), '150.75');
      await tester.pump();
      expect(priceError, isNull);

      await tester.enterText(textFields.at(2), 'abc');
      await tester.pump();
      expect(priceError, equals('Please enter a valid price'));
    });

    testWidgets('should validate date and time fields', (WidgetTester tester) async {
      String? dateError;
      String? timeError;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ValidatedTextField(
                  label: 'Date',
                  validationType: ValidationType.date,
                  hintText: 'YYYY-MM-DD',
                  onChanged: (value) {
                    dateError = InputValidation.getDateError(value);
                  },
                ),
                ValidatedTextField(
                  label: 'Time',
                  validationType: ValidationType.time,
                  hintText: 'HH:MM',
                  onChanged: (value) {
                    timeError = InputValidation.getTimeError(value);
                  },
                ),
              ],
            ),
          ),
        ),
      );

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      // Test date field
      await tester.enterText(textFields.at(0), '2024-12-31');
      await tester.pump();
      expect(dateError, isNull);

      await tester.enterText(textFields.at(0), '31-12-2024');
      await tester.pump();
      expect(dateError, equals('Please use YYYY-MM-DD format'));

      // Test time field
      await tester.enterText(textFields.at(1), '14:30');
      await tester.pump();
      expect(timeError, isNull);

      await tester.enterText(textFields.at(1), '25:00');
      await tester.pump();
      expect(timeError, equals('Please enter a valid time'));
    });

    testWidgets('should show and hide password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValidatedTextField(
              label: 'Password',
              validationType: ValidationType.password,
              obscureText: true,
            ),
          ),
        ),
      );

      // Find the text field and visibility toggle
      final textField = find.byType(TextField);
      final visibilityButton = find.byIcon(Icons.visibility_off);
      
      expect(textField, findsOneWidget);
      expect(visibilityButton, findsOneWidget);

      // Initially password should be obscured
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.obscureText, isTrue);

      // Tap visibility toggle
      await tester.tap(visibilityButton);
      await tester.pump();

      // Password should now be visible
      final updatedTextFieldWidget = tester.widget<TextField>(textField);
      expect(updatedTextFieldWidget.obscureText, isFalse);

      // Icon should change
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
    });

    testWidgets('should handle field focus and blur events', (WidgetTester tester) async {
      bool wasFocused = false;
      bool wasUnfocused = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValidatedTextField(
              label: 'Email',
              validationType: ValidationType.email,
              onFocusChanged: (hasFocus) {
                if (hasFocus) {
                  wasFocused = true;
                } else {
                  wasUnfocused = true;
                }
              },
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Tap to focus
      await tester.tap(textField);
      await tester.pump();
      
      expect(wasFocused, isTrue);
      expect(wasUnfocused, isFalse);

      // Tap elsewhere to unfocus
      await tester.tap(find.byType(Scaffold));
      await tester.pump();
      
      expect(wasUnfocused, isTrue);
    });

    testWidgets('should display helper text and error messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValidatedTextField(
              label: 'Email',
              validationType: ValidationType.email,
              helperText: 'Enter your email address',
            ),
          ),
        ),
      );

      // Check for helper text
      expect(find.text('Enter your email address'), findsOneWidget);

      final textField = find.byType(TextField);
      
      // Enter invalid email to trigger error
      await tester.enterText(textField, 'invalid');
      await tester.pump();
      
      // Error message should appear
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('should handle custom validation rules', (WidgetTester tester) async {
      String? customError;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValidatedTextField(
              label: 'Custom Field',
              validationType: ValidationType.custom,
              customValidator: (value) {
                if (value == null || value.isEmpty) {
                  customError = 'Custom field is required';
                  return false;
                }
                if (!value.startsWith('custom_')) {
                  customError = 'Value must start with "custom_"';
                  return false;
                }
                customError = null;
                return true;
              },
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Test empty value
      await tester.enterText(textField, '');
      await tester.pump();
      expect(customError, equals('Custom field is required'));

      // Test invalid prefix
      await tester.enterText(textField, 'invalid_value');
      await tester.pump();
      expect(customError, equals('Value must start with "custom_"'));

      // Test valid value
      await tester.enterText(textField, 'custom_value');
      await tester.pump();
      expect(customError, isNull);
    });

    testWidgets('should handle form submission validation', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      bool formSubmitted = false;
      Map<String, String?> formErrors = {};
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  ValidatedTextField(
                    label: 'Email',
                    validationType: ValidationType.email,
                    onValidationChanged: (error) {
                      formErrors['email'] = error;
                    },
                  ),
                  ValidatedTextField(
                    label: 'Password',
                    validationType: ValidationType.password,
                    obscureText: true,
                    onValidationChanged: (error) {
                      formErrors['password'] = error;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formSubmitted = true;
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final submitButton = find.byType(ElevatedButton);
      final textFields = find.byType(TextField);
      
      // Try to submit empty form
      await tester.tap(submitButton);
      await tester.pump();
      
      expect(formSubmitted, isFalse);
      expect(formErrors['email'], equals('Email is required'));
      expect(formErrors['password'], equals('Password is required'));

      // Fill form with valid data
      await tester.enterText(textFields.at(0), 'test@example.com');
      await tester.enterText(textFields.at(1), 'StrongP@ssw0rd');
      await tester.pump();
      
      // Submit valid form
      await tester.tap(submitButton);
      await tester.pump();
      
      expect(formSubmitted, isTrue);
      expect(formErrors['email'], isNull);
      expect(formErrors['password'], isNull);
    });

    testWidgets('should handle debounced validation', (WidgetTester tester) async {
      int validationCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValidatedTextField(
              label: 'Email',
              validationType: ValidationType.email,
              debounceTime: const Duration(milliseconds: 500),
              onChanged: (value) {
                validationCount++;
              },
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      
      // Type quickly (debounced validation should not trigger on each keystroke)
      await tester.enterText(textField, 't');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(textField, 'te');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(textField, 'tes');
      await tester.pump(const Duration(milliseconds: 100));
      
      // Validation count should be minimal due to debouncing
      expect(validationCount, lessThan(3));
      
      // Wait for debounce to complete
      await tester.pump(const Duration(milliseconds: 500));
      
      // Final validation should trigger
      expect(validationCount, greaterThan(0));
    });

    testWidgets('should handle accessibility features', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValidatedTextField(
              label: 'Email',
              validationType: ValidationType.email,
              semanticsLabel: 'Email address field',
            ),
          ),
        ),
      );

      // Check for semantic labels
      expect(find.bySemanticsLabel('Email address field'), findsOneWidget);
      
      // Check that the field is focusable for accessibility
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      
      await tester.tap(textField);
      await tester.pump();
      
      // Field should be focused
      final focusedNode = tester.widget<TextField>(textField).focusNode;
      expect(focusedNode?.hasFocus, isTrue);
    });

    testWidgets('should handle different keyboard types', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ValidatedTextField(
                  label: 'Email',
                  validationType: ValidationType.email,
                ),
                ValidatedTextField(
                  label: 'Phone',
                  validationType: ValidationType.phone,
                ),
                ValidatedTextField(
                  label: 'Weight',
                  validationType: ValidationType.weight,
                ),
                ValidatedTextField(
                  label: 'Name',
                  validationType: ValidationType.name,
                ),
              ],
            ),
          ),
        ),
      );

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(4));

      // Check keyboard types
      final emailField = tester.widget<TextField>(textFields.at(0));
      expect(emailField.keyboardType, equals(TextInputType.emailAddress));

      final phoneField = tester.widget<TextField>(textFields.at(1));
      expect(phoneField.keyboardType, equals(TextInputType.phone));

      final weightField = tester.widget<TextField>(textFields.at(2));
      expect(weightField.keyboardType, equals(TextInputType.number));

      final nameField = tester.widget<TextField>(textFields.at(3));
      expect(nameField.keyboardType, equals(TextInputType.text));
    });

    testWidgets('should handle input formatters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValidatedTextField(
              label: 'Phone',
              validationType: ValidationType.phone,
              inputFormatters: [
                // Phone number formatter (simplified)
                FilteringTextInputFormatter.deny(RegExp(r'[^0-9+]')),
              ],
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      
      // Try to enter letters (should be filtered out)
      await tester.enterText(textField, 'abc123');
      await tester.pump();
      
      // Should only contain numbers and +
      final textFieldWidget = tester.widget<TextField>(textField);
      final controller = textFieldWidget.controller;
      expect(controller?.text, equals('123')); // Letters filtered out
    });
  });

  group('Form Integration Tests', () {
    testWidgets('should validate complete registration form', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      bool formValid = false;
      Map<String, String?> allErrors = {};
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ValidatedTextField(
                      label: 'Business Name',
                      validationType: ValidationType.businessName,
                      onValidationChanged: (error) => allErrors['businessName'] = error,
                    ),
                    ValidatedTextField(
                      label: 'Email',
                      validationType: ValidationType.email,
                      onValidationChanged: (error) => allErrors['email'] = error,
                    ),
                    ValidatedTextField(
                      label: 'Phone',
                      validationType: ValidationType.phone,
                      onValidationChanged: (error) => allErrors['phone'] = error,
                    ),
                    ValidatedTextField(
                      label: 'Address',
                      validationType: ValidationType.address,
                      onValidationChanged: (error) => allErrors['address'] = error,
                    ),
                    ValidatedTextField(
                      label: 'Password',
                      validationType: ValidationType.password,
                      obscureText: true,
                      onValidationChanged: (error) => allErrors['password'] = error,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          formValid = true;
                        }
                      },
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final submitButton = find.byType(ElevatedButton);
      final textFields = find.byType(TextField);
      
      // Initially form should be invalid
      await tester.tap(submitButton);
      await tester.pump();
      
      expect(formValid, isFalse);
      expect(allErrors['businessName'], equals('Business name is required'));
      expect(allErrors['email'], equals('Email is required'));
      expect(allErrors['phone'], equals('Phone number is required'));
      expect(allErrors['address'], equals('Address is required'));
      expect(allErrors['password'], equals('Password is required'));

      // Fill with valid data
      await tester.enterText(textFields.at(0), 'OptiFlow Logistics');
      await tester.enterText(textFields.at(1), 'contact@optiflow.com');
      await tester.enterText(textFields.at(2), '+22720123456');
      await tester.enterText(textFields.at(3), '123 Main St, Niamey, Niger');
      await tester.enterText(textFields.at(4), 'SecureP@ssw0rd123');
      await tester.pump();
      
      // Submit valid form
      await tester.tap(submitButton);
      await tester.pump();
      
      expect(formValid, isTrue);
      expect(allErrors.values.every((error) => error == null), isTrue);
    });

    testWidgets('should handle real-time validation feedback', (WidgetTester tester) async {
      String? currentError;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValidatedTextField(
              label: 'Email',
              validationType: ValidationType.email,
              onValidationChanged: (error) {
                currentError = error;
              },
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      
      // Start typing invalid email
      await tester.enterText(textField, 'invalid');
      await tester.pump();
      
      expect(currentError, isNotNull);
      expect(currentError, equals('Please enter a valid email address'));

      // Complete the email to make it valid
      await tester.enterText(textField, 'invalid@example.com');
      await tester.pump();
      
      expect(currentError, isNull);

      // Clear the field
      await tester.enterText(textField, '');
      await tester.pump();
      
      expect(currentError, equals('Email is required'));
    });
  });
}
