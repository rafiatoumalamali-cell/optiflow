import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optiflow/utils/input_validation.dart';

void main() {
  group('Input Validation Tests', () {
    group('Email Validation', () {
      test('should validate correct email addresses', () {
        expect(InputValidation.isValidEmail('test@example.com'), isTrue);
        expect(InputValidation.isValidEmail('user.name@domain.co.uk'), isTrue);
        expect(InputValidation.isValidEmail('user+tag@example.org'), isTrue);
        expect(InputValidation.isValidEmail('user123@test-domain.com'), isTrue);
        expect(InputValidation.isValidEmail('a@b.c'), isTrue);
      });

      test('should reject invalid email addresses', () {
        expect(InputValidation.isValidEmail(''), isFalse);
        expect(InputValidation.isValidEmail('invalid'), isFalse);
        expect(InputValidation.isValidEmail('test@'), isFalse);
        expect(InputValidation.isValidEmail('@example.com'), isFalse);
        expect(InputValidation.isValidEmail('test.example.com'), isFalse);
        expect(InputValidation.isValidEmail('test@.com'), isFalse);
        expect(InputValidation.isValidEmail('test@example.'), isFalse);
        expect(InputValidation.isValidEmail('test@example..com'), isFalse);
        expect(InputValidation.isValidEmail('test@example.c'), isFalse);
        expect(InputValidation.isValidEmail('test email@example.com'), isFalse);
      });

      test('should handle null email gracefully', () {
        expect(InputValidation.isValidEmail(null), isFalse);
      });

      test('should provide email error messages', () {
        expect(InputValidation.getEmailError(''), equals('Email is required'));
        expect(InputValidation.getEmailError('invalid'), equals('Please enter a valid email address'));
        expect(InputValidation.getEmailError('test@example.com'), isNull);
        expect(InputValidation.getEmailError(null), equals('Email is required'));
      });
    });

    group('Phone Number Validation', () {
      test('should validate correct phone numbers', () {
        expect(InputValidation.isValidPhoneNumber('+1234567890'), isTrue);
        expect(InputValidation.isValidPhoneNumber('+1 234-567-8900'), isTrue);
        expect(InputValidation.isValidPhoneNumber('+44 20 7946 0958'), isTrue);
        expect(InputValidation.isValidPhoneNumber('+227 20 123 456'), isTrue); // Niger
        expect(InputValidation.isValidPhoneNumber('22720123456'), isTrue); // Local format
        expect(InputValidation.isValidPhoneNumber('0123456789'), isTrue);
      });

      test('should reject invalid phone numbers', () {
        expect(InputValidation.isValidPhoneNumber(''), isFalse);
        expect(InputValidation.isValidPhoneNumber('123'), isFalse);
        expect(InputValidation.isValidPhoneNumber('abc'), isFalse);
        expect(InputValidation.isValidPhoneNumber('123abc'), isFalse);
        expect(InputValidation.isValidPhoneNumber('+'), isFalse);
        expect(InputValidation.isValidPhoneNumber('1'), isFalse);
        expect(InputValidation.isValidPhoneNumber('+12345678901234567890'), isFalse); // Too long
      });

      test('should handle null phone number gracefully', () {
        expect(InputValidation.isValidPhoneNumber(null), isFalse);
      });

      test('should provide phone error messages', () {
        expect(InputValidation.getPhoneError(''), equals('Phone number is required'));
        expect(InputValidation.getPhoneError('123'), equals('Please enter a valid phone number'));
        expect(InputValidation.getPhoneError('+1234567890'), isNull);
        expect(InputValidation.getPhoneError(null), equals('Phone number is required'));
      });

      test('should format phone numbers correctly', () {
        expect(InputValidation.formatPhoneNumber('22720123456'), equals('+227 20 123 456'));
        expect(InputValidation.formatPhoneNumber('+22720123456'), equals('+227 20 123 456'));
        expect(InputValidation.formatPhoneNumber('0123456789'), equals('+1 234-567-890'));
        expect(InputValidation.formatPhoneNumber('invalid'), equals('invalid'));
      });
    });

    group('Password Validation', () {
      test('should validate strong passwords', () {
        expect(InputValidation.isValidPassword('StrongP@ssw0rd'), isTrue);
        expect(InputValidation.isValidPassword('MySecure123!'), isTrue);
        expect(InputValidation.isValidPassword('ComplexP@ssw0rd#'), isTrue);
        expect(InputValidation.isValidPassword('Aa1!Aa1!Aa1!'), isTrue);
      });

      test('should reject weak passwords', () {
        expect(InputValidation.isValidPassword(''), isFalse);
        expect(InputValidation.isValidPassword('password'), isFalse);
        expect(InputValidation.isValidPassword('12345678'), isFalse);
        expect(InputValidation.isValidPassword('abcdefgh'), isFalse);
        expect(InputValidation.isValidPassword('ABCDEFGH'), isFalse);
        expect(InputValidation.isValidPassword('Abc123'), isFalse); // Too short
        expect(InputValidation.isValidPassword('Password123'), isFalse); // No special char
        expect(InputValidation.isValidPassword('Password!'), isFalse); // No number
        expect(InputValidation.isValidPassword('password123!'), isFalse); // No uppercase
        expect(InputValidation.isValidPassword('PASSWORD123!'), isFalse); // No lowercase
      });

      test('should handle null password gracefully', () {
        expect(InputValidation.isValidPassword(null), isFalse);
      });

      test('should provide password error messages', () {
        expect(InputValidation.getPasswordError(''), equals('Password is required'));
        expect(InputValidation.getPasswordError('123'), equals('Password must be at least 8 characters'));
        expect(InputValidation.getPasswordError('password'), equals('Password must contain uppercase letter'));
        expect(InputValidation.getPasswordError('PASSWORD'), equals('Password must contain lowercase letter'));
        expect(InputValidation.getPasswordError('Password'), equals('Password must contain number'));
        expect(InputValidation.getPasswordError('Password123'), equals('Password must contain special character'));
        expect(InputValidation.getPasswordError('StrongP@ssw0rd'), isNull);
        expect(InputValidation.getPasswordError(null), equals('Password is required'));
      });

      test('should calculate password strength', () {
        expect(InputValidation.getPasswordStrength(''), equals(0));
        expect(InputValidation.getPasswordStrength('123'), equals(1));
        expect(InputValidation.getPasswordStrength('password'), equals(2));
        expect(InputValidation.getPasswordStrength('Password'), equals(3));
        expect(InputValidation.getPasswordStrength('Password123'), equals(4));
        expect(InputValidation.getPasswordStrength('StrongP@ssw0rd'), equals(5));
      });

      test('should get password strength description', () {
        expect(InputValidation.getPasswordStrengthDescription(0), equals('Very Weak'));
        expect(InputValidation.getPasswordStrengthDescription(1), equals('Weak'));
        expect(InputValidation.getPasswordStrengthDescription(2), equals('Fair'));
        expect(InputValidation.getPasswordStrengthDescription(3), equals('Good'));
        expect(InputValidation.getPasswordStrengthDescription(4), equals('Strong'));
        expect(InputValidation.getPasswordStrengthDescription(5), equals('Very Strong'));
      });
    });

    group('Name Validation', () {
      test('should validate correct names', () {
        expect(InputValidation.isValidName('John Doe'), isTrue);
        expect(InputValidation.isValidName('Mary Jane Smith'), isTrue);
        expect(InputValidation.isValidName('Jean-Claude Van Damme'), isTrue);
        expect(InputValidation.isValidName('O\'Connor'), isTrue);
        expect(InputValidation.isValidName('Dr. John Smith'), isTrue);
        expect(InputValidation.isValidName('Aïssa'), isTrue); // Unicode name
        expect(InputValidation.isValidName('José'), isTrue); // Unicode name
      });

      test('should reject invalid names', () {
        expect(InputValidation.isValidName(''), isFalse);
        expect(InputValidation.isValidName('J'), isFalse); // Too short
        expect(InputValidation.isValidName('John123'), isFalse);
        expect(InputValidation.isValidName('John@Doe'), isFalse);
        expect(InputValidation.isValidName('   '), isFalse); // Only spaces
        expect(InputValidation.isValidName('123456'), isFalse);
        expect(InputValidation.isValidName('!@#$%'), isFalse);
        expect(InputValidation.isValidName('a' * 101), isFalse); // Too long
      });

      test('should handle null name gracefully', () {
        expect(InputValidation.isValidName(null), isFalse);
      });

      test('should provide name error messages', () {
        expect(InputValidation.getNameError(''), equals('Name is required'));
        expect(InputValidation.getNameError('J'), equals('Name must be at least 2 characters'));
        expect(InputValidation.getNameError('John123'), equals('Name can only contain letters, spaces, hyphens, and apostrophes'));
        expect(InputValidation.getNameError('a' * 101), equals('Name must be less than 100 characters'));
        expect(InputValidation.getNameError('John Doe'), isNull);
        expect(InputValidation.getNameError(null), equals('Name is required'));
      });

      test('should format names correctly', () {
        expect(InputValidation.formatName('john doe'), equals('John Doe'));
        expect(InputValidation.formatName('JOHN DOE'), equals('John Doe'));
        expect(InputValidation.formatName('john'), equals('John'));
        expect(InputValidation.formatName('  john doe  '), equals('John Doe'));
        expect(InputValidation.formatName('jean-claude van damme'), equals('Jean-Claude Van Damme'));
      });
    });

    group('Address Validation', () {
      test('should validate correct addresses', () {
        expect(InputValidation.isValidAddress('123 Main St, Niamey, Niger'), isTrue);
        expect(InputValidation.isValidAddress('Avenue de la Révolution, Niamey'), isTrue);
        expect(InputValidation.isValidAddress('B.P. 12345 Niamey, Niger'), isTrue);
        expect(InputValidation.isValidAddress('Quartier Plateau, Niamey'), isTrue);
        expect(InputValidation.isValidAddress('123 Street Name, City, Country'), isTrue);
      });

      test('should reject invalid addresses', () {
        expect(InputValidation.isValidAddress(''), isFalse);
        expect(InputValidation.isValidAddress('123'), isFalse); // Too short
        expect(InputValidation.isValidAddress('   '), isFalse); // Only spaces
        expect(InputValidation.isValidAddress('a' * 501), isFalse); // Too long
      });

      test('should handle null address gracefully', () {
        expect(InputValidation.isValidAddress(null), isFalse);
      });

      test('should provide address error messages', () {
        expect(InputValidation.getAddressError(''), equals('Address is required'));
        expect(InputValidation.getAddressError('123'), equals('Address must be at least 5 characters'));
        expect(InputValidation.getAddressError('a' * 501), equals('Address must be less than 500 characters'));
        expect(InputValidation.getAddressError('123 Main St, Niamey, Niger'), isNull);
        expect(InputValidation.getAddressError(null), equals('Address is required'));
      });
    });

    group('Business Name Validation', () {
      test('should validate correct business names', () {
        expect(InputValidation.isValidBusinessName('OptiFlow Logistics'), isTrue);
        expect(InputValidation.isValidBusinessName('Niamey Delivery Services'), isTrue);
        expect(InputValidation.isValidBusinessName('Sahara Transport Co.'), isTrue);
        expect(InputValidation.isValidBusinessName('123 Logistics'), isTrue); // Numbers allowed
        expect(InputValidation.isValidBusinessName('Global-Express Delivery'), isTrue);
      });

      test('should reject invalid business names', () {
        expect(InputValidation.isValidBusinessName(''), isFalse);
        expect(InputValidation.isValidBusinessName('A'), isFalse); // Too short
        expect(InputValidation.isValidBusinessName('   '), isFalse); // Only spaces
        expect(InputValidation.isValidBusinessName('Business@Name'), isFalse);
        expect(InputValidation.isValidBusinessName('Business#Name'), isFalse);
        expect(InputValidation.isValidBusinessName('a' * 101), isFalse); // Too long
      });

      test('should handle null business name gracefully', () {
        expect(InputValidation.isValidBusinessName(null), isFalse);
      });

      test('should provide business name error messages', () {
        expect(InputValidation.getBusinessNameError(''), equals('Business name is required'));
        expect(InputValidation.getBusinessNameError('A'), equals('Business name must be at least 2 characters'));
        expect(InputValidation.getBusinessNameError('Business@Name'), equals('Business name contains invalid characters'));
        expect(InputValidation.getBusinessNameError('a' * 101), equals('Business name must be less than 100 characters'));
        expect(InputValidation.getBusinessNameError('OptiFlow Logistics'), isNull);
        expect(InputValidation.getBusinessNameError(null), equals('Business name is required'));
      });
    });

    group('Vehicle Registration Validation', () {
      test('should validate correct vehicle registrations', () {
        expect(InputValidation.isValidVehicleRegistration('NE-123-AB'), isTrue); // Niger format
        expect(InputValidation.isValidVehicleRegistration('NE1234AB'), isTrue); // Compact format
        expect(InputValidation.isValidVehicleRegistration('123456'), isTrue); // Simple numeric
        expect(InputValidation.isValidVehicleRegistration('ABC123'), isTrue); // Alphanumeric
      });

      test('should reject invalid vehicle registrations', () {
        expect(InputValidation.isValidVehicleRegistration(''), isFalse);
        expect(InputValidation.isValidVehicleRegistration('12'), isFalse); // Too short
        expect(InputValidation.isValidVehicleRegistration('   '), isFalse); // Only spaces
        expect(InputValidation.isValidVehicleRegistration('ABC'), isFalse); // Too short
        expect(InputValidation.isValidVehicleRegistration('a' * 21), isFalse); // Too long
        expect(InputValidation.isValidVehicleRegistration('ABC@123'), isFalse); // Invalid chars
      });

      test('should handle null vehicle registration gracefully', () {
        expect(InputValidation.isValidVehicleRegistration(null), isFalse);
      });

      test('should provide vehicle registration error messages', () {
        expect(InputValidation.getVehicleRegistrationError(''), equals('Vehicle registration is required'));
        expect(InputValidation.getVehicleRegistrationError('12'), equals('Vehicle registration must be at least 3 characters'));
        expect(InputValidation.getVehicleRegistrationError('a' * 21), equals('Vehicle registration must be less than 20 characters'));
        expect(InputValidation.getVehicleRegistrationError('ABC@123'), equals('Vehicle registration contains invalid characters'));
        expect(InputValidation.getVehicleRegistrationError('NE-123-AB'), isNull);
        expect(InputValidation.getVehicleRegistrationError(null), equals('Vehicle registration is required'));
      });
    });

    group('Weight Validation', () {
      test('should validate correct weights', () {
        expect(InputValidation.isValidWeight('10.5'), isTrue);
        expect(InputValidation.isValidWeight('100'), isTrue);
        expect(InputValidation.isValidWeight('0.5'), isTrue);
        expect(InputValidation.isValidWeight('5000'), isTrue);
        expect(InputValidation.isValidWeight('1000.25'), isTrue);
      });

      test('should reject invalid weights', () {
        expect(InputValidation.isValidWeight(''), isFalse);
        expect(InputValidation.isValidWeight('0'), isFalse); // Zero weight
        expect(InputValidation.isValidWeight('-10'), isFalse); // Negative
        expect(InputValidation.isValidWeight('abc'), isFalse);
        expect(InputValidation.isValidWeight('10.5.5'), isFalse);
        expect(InputValidation.isValidWeight('10000'), isFalse); // Too heavy
        expect(InputValidation.isValidWeight('0.01'), isFalse); // Too light
      });

      test('should handle null weight gracefully', () {
        expect(InputValidation.isValidWeight(null), isFalse);
      });

      test('should provide weight error messages', () {
        expect(InputValidation.getWeightError(''), equals('Weight is required'));
        expect(InputValidation.getWeightError('0'), equals('Weight must be greater than 0'));
        expect(InputValidation.getWeightError('-10'), equals('Weight must be greater than 0'));
        expect(InputValidation.getWeightError('abc'), equals('Please enter a valid weight'));
        expect(InputValidation.getWeightError('10000'), equals('Weight must be less than 5000 kg'));
        expect(InputValidation.getWeightError('10.5'), isNull);
        expect(InputValidation.getWeightError(null), equals('Weight is required'));
      });

      test('should parse weight correctly', () {
        expect(InputValidation.parseWeight('10.5'), equals(10.5));
        expect(InputValidation.parseWeight('100'), equals(100.0));
        expect(InputValidation.parseWeight('0.5'), equals(0.5));
        expect(InputValidation.parseWeight('invalid'), isNull);
        expect(InputValidation.parseWeight(null), isNull);
      });
    });

    group('Distance Validation', () {
      test('should validate correct distances', () {
        expect(InputValidation.isValidDistance('1.5'), isTrue);
        expect(InputValidation.isValidDistance('10'), isTrue);
        expect(InputValidation.isValidDistance('0.1'), isTrue);
        expect(InputValidation.isValidDistance('100'), isTrue);
        expect(InputValidation.isValidDistance('500.25'), isTrue);
      });

      test('should reject invalid distances', () {
        expect(InputValidation.isValidDistance(''), isFalse);
        expect(InputValidation.isValidDistance('0'), isFalse); // Zero distance
        expect(InputValidation.isValidDistance('-10'), isFalse); // Negative
        expect(InputValidation.isValidDistance('abc'), isFalse);
        expect(InputValidation.isValidDistance('10.5.5'), isFalse);
        expect(InputValidation.isValidDistance('1000'), isFalse); // Too far
        expect(InputValidation.isValidDistance('0.01'), isFalse); // Too short
      });

      test('should handle null distance gracefully', () {
        expect(InputValidation.isValidDistance(null), isFalse);
      });

      test('should provide distance error messages', () {
        expect(InputValidation.getDistanceError(''), equals('Distance is required'));
        expect(InputValidation.getDistanceError('0'), equals('Distance must be greater than 0'));
        expect(InputValidation.getDistanceError('-10'), equals('Distance must be greater than 0'));
        expect(InputValidation.getDistanceError('abc'), equals('Please enter a valid distance'));
        expect(InputValidation.getDistanceError('1000'), equals('Distance must be less than 500 km'));
        expect(InputValidation.getDistanceError('10.5'), isNull);
        expect(InputValidation.getDistanceError(null), equals('Distance is required'));
      });

      test('should parse distance correctly', () {
        expect(InputValidation.parseDistance('1.5'), equals(1.5));
        expect(InputValidation.parseDistance('10'), equals(10.0));
        expect(InputValidation.parseDistance('0.1'), equals(0.1));
        expect(InputValidation.parseDistance('invalid'), isNull);
        expect(InputValidation.parseDistance(null), isNull);
      });
    });

    group('Price Validation', () {
      test('should validate correct prices', () {
        expect(InputValidation.isValidPrice('10.50'), isTrue);
        expect(InputValidation.isValidPrice('100'), isTrue);
        expect(InputValidation.isValidPrice('0.01'), isTrue);
        expect(InputValidation.isValidPrice('999999'), isTrue);
        expect(InputValidation.isValidPrice('5000.25'), isTrue);
      });

      test('should reject invalid prices', () {
        expect(InputValidation.isValidPrice(''), isFalse);
        expect(InputValidation.isValidPrice('0'), isFalse); // Zero price
        expect(InputValidation.isValidPrice('-10'), isFalse); // Negative
        expect(InputValidation.isValidPrice('abc'), isFalse);
        expect(InputValidation.isValidPrice('10.5.5'), isFalse);
        expect(InputValidation.isValidPrice('1000000'), isFalse); // Too expensive
      });

      test('should handle null price gracefully', () {
        expect(InputValidation.isValidPrice(null), isFalse);
      });

      test('should provide price error messages', () {
        expect(InputValidation.getPriceError(''), equals('Price is required'));
        expect(InputValidation.getPriceError('0'), equals('Price must be greater than 0'));
        expect(InputValidation.getPriceError('-10'), equals('Price must be greater than 0'));
        expect(InputValidation.getPriceError('abc'), equals('Please enter a valid price'));
        expect(InputValidation.getPriceError('1000000'), equals('Price must be less than 999999'));
        expect(InputValidation.getPriceError('10.50'), isNull);
        expect(InputValidation.getPriceError(null), equals('Price is required'));
      });

      test('should parse price correctly', () {
        expect(InputValidation.parsePrice('10.50'), equals(10.50));
        expect(InputValidation.parsePrice('100'), equals(100.0));
        expect(InputValidation.parsePrice('0.01'), equals(0.01));
        expect(InputValidation.parsePrice('invalid'), isNull);
        expect(InputValidation.parsePrice(null), isNull);
      });

      test('should format price correctly', () {
        expect(InputValidation.formatPrice(10.50), equals('10.50'));
        expect(InputValidation.formatPrice(100), equals('100.00'));
        expect(InputValidation.formatPrice(0.01), equals('0.01'));
        expect(InputValidation.formatPrice(1000.5), equals('1000.50'));
      });
    });

    group('Quantity Validation', () {
      test('should validate correct quantities', () {
        expect(InputValidation.isValidQuantity('1'), isTrue);
        expect(InputValidation.isValidQuantity('10'), isTrue);
        expect(InputValidation.isValidQuantity('100'), isTrue);
        expect(InputValidation.isValidQuantity('1000'), isTrue);
      });

      test('should reject invalid quantities', () {
        expect(InputValidation.isValidQuantity(''), isFalse);
        expect(InputValidation.isValidQuantity('0'), isFalse); // Zero quantity
        expect(InputValidation.isValidQuantity('-1'), isFalse); // Negative
        expect(InputValidation.isValidQuantity('abc'), isFalse);
        expect(InputValidation.isValidQuantity('10.5'), isFalse); // Decimal not allowed
        expect(InputValidation.isValidQuantity('10000'), isFalse); // Too large
      });

      test('should handle null quantity gracefully', () {
        expect(InputValidation.isValidQuantity(null), isFalse);
      });

      test('should provide quantity error messages', () {
        expect(InputValidation.getQuantityError(''), equals('Quantity is required'));
        expect(InputValidation.getQuantityError('0'), equals('Quantity must be greater than 0'));
        expect(InputValidation.getQuantityError('-1'), equals('Quantity must be greater than 0'));
        expect(InputValidation.getQuantityError('abc'), equals('Please enter a valid quantity'));
        expect(InputValidation.getQuantityError('10.5'), equals('Quantity must be a whole number'));
        expect(InputValidation.getQuantityError('10000'), equals('Quantity must be less than 10000'));
        expect(InputValidation.getQuantityError('10'), isNull);
        expect(InputValidation.getQuantityError(null), equals('Quantity is required'));
      });

      test('should parse quantity correctly', () {
        expect(InputValidation.parseQuantity('10'), equals(10));
        expect(InputValidation.parseQuantity('100'), equals(100));
        expect(InputValidation.parseQuantity('1'), equals(1));
        expect(InputValidation.parseQuantity('invalid'), isNull);
        expect(InputValidation.parseQuantity(null), isNull);
      });
    });

    group('URL Validation', () {
      test('should validate correct URLs', () {
        expect(InputValidation.isValidUrl('https://www.example.com'), isTrue);
        expect(InputValidation.isValidUrl('http://example.com'), isTrue);
        expect(InputValidation.isValidUrl('https://optiflow.com'), isTrue);
        expect(InputValidation.isValidUrl('https://www.optiflow.co.uk'), isTrue);
        expect(InputValidation.isValidUrl('https://api.optiflow.com/v1'), isTrue);
      });

      test('should reject invalid URLs', () {
        expect(InputValidation.isValidUrl(''), isFalse);
        expect(InputValidation.isValidUrl('www.example.com'), isFalse); // Missing protocol
        expect(InputValidation.isValidUrl('example.com'), isFalse); // Missing protocol
        expect(InputValidation.isValidUrl('ftp://example.com'), isFalse); // Wrong protocol
        expect(InputValidation.isValidUrl('https://'), isFalse); // Missing domain
        expect(InputValidation.isValidUrl('https://example'), isFalse); // Invalid domain
      });

      test('should handle null URL gracefully', () {
        expect(InputValidation.isValidUrl(null), isFalse);
      });

      test('should provide URL error messages', () {
        expect(InputValidation.getUrlError(''), equals('URL is required'));
        expect(InputValidation.getUrlError('www.example.com'), equals('Please enter a valid URL'));
        expect(InputValidation.getUrlError('ftp://example.com'), equals('Please enter a valid URL'));
        expect(InputValidation.getUrlError('https://www.example.com'), isNull);
        expect(InputValidation.getUrlError(null), equals('URL is required'));
      });
    });

    group('Date Validation', () {
      test('should validate correct dates', () {
        expect(InputValidation.isValidDate('2024-12-31'), isTrue);
        expect(InputValidation.isValidDate('2024-01-01'), isTrue);
        expect(InputValidation.isValidDate('2024-02-29'), isTrue); // Leap year
        expect(InputValidation.isValidDate('2023-12-31'), isTrue);
      });

      test('should reject invalid dates', () {
        expect(InputValidation.isValidDate(''), isFalse);
        expect(InputValidation.isValidDate('2024-13-01'), isFalse); // Invalid month
        expect(InputValidation.isValidDate('2024-02-30'), isFalse); // Invalid day
        expect(InputValidation.isValidDate('2023-02-29'), isFalse); // Not leap year
        expect(InputValidation.isValidDate('31-12-2024'), isFalse); // Wrong format
        expect(InputValidation.isValidDate('2024/12/31'), isFalse); // Wrong separator
        expect(InputValidation.isValidDate('2024-12'), isFalse); // Incomplete
        expect(InputValidation.isValidDate('2024-12-31-12'), isFalse); // Too many parts
      });

      test('should handle null date gracefully', () {
        expect(InputValidation.isValidDate(null), isFalse);
      });

      test('should provide date error messages', () {
        expect(InputValidation.getDateError(''), equals('Date is required'));
        expect(InputValidation.getDateError('2024-13-01'), equals('Please enter a valid date'));
        expect(InputValidation.getDateError('2024-02-30'), equals('Please enter a valid date'));
        expect(InputValidation.getDateError('31-12-2024'), equals('Please use YYYY-MM-DD format'));
        expect(InputValidation.getDateError('2024-12-31'), isNull);
        expect(InputValidation.getDateError(null), equals('Date is required'));
      });

      test('should parse date correctly', () {
        final date = InputValidation.parseDate('2024-12-31');
        expect(date, isNotNull);
        expect(date!.year, equals(2024));
        expect(date.month, equals(12));
        expect(date.day, equals(31));
        
        expect(InputValidation.parseDate('invalid'), isNull);
        expect(InputValidation.parseDate(null), isNull);
      });

      test('should format date correctly', () {
        final date = DateTime(2024, 12, 31);
        expect(InputValidation.formatDate(date), equals('2024-12-31'));
      });

      test('should validate date ranges', () {
        expect(InputValidation.isDateInRange('2024-12-31', '2024-01-01', '2024-12-31'), isTrue);
        expect(InputValidation.isDateInRange('2024-06-15', '2024-01-01', '2024-12-31'), isTrue);
        expect(InputValidation.isDateInRange('2023-12-31', '2024-01-01', '2024-12-31'), isFalse);
        expect(InputValidation.isDateInRange('2025-01-01', '2024-01-01', '2024-12-31'), isFalse);
      });
    });

    group('Time Validation', () {
      test('should validate correct times', () {
        expect(InputValidation.isValidTime('00:00'), isTrue);
        expect(InputValidation.isValidTime('12:30'), isTrue);
        expect(InputValidation.isValidTime('23:59'), isTrue);
        expect(InputValidation.isValidTime('09:05'), isTrue);
      });

      test('should reject invalid times', () {
        expect(InputValidation.isValidTime(''), isFalse);
        expect(InputValidation.isValidTime('24:00'), isFalse); // Invalid hour
        expect(InputValidation.isValidTime('12:60'), isFalse); // Invalid minute
        expect(InputValidation.isValidTime('25:30'), isFalse); // Invalid hour
        expect(InputValidation.isValidTime('12:61'), isFalse); // Invalid minute
        expect(InputValidation.isValidTime('12.30'), isFalse); // Wrong separator
        expect(InputValidation.isValidTime('12'), isFalse); // Incomplete
        expect(InputValidation.isValidTime('12:30:45'), isFalse); // Too many parts
      });

      test('should handle null time gracefully', () {
        expect(InputValidation.isValidTime(null), isFalse);
      });

      test('should provide time error messages', () {
        expect(InputValidation.getTimeError(''), equals('Time is required'));
        expect(InputValidation.getTimeError('24:00'), equals('Please enter a valid time'));
        expect(InputValidation.getTimeError('12:60'), equals('Please enter a valid time'));
        expect(InputValidation.getTimeError('12.30'), equals('Please use HH:MM format'));
        expect(InputValidation.getTimeError('12:30'), isNull);
        expect(InputValidation.getTimeError(null), equals('Time is required'));
      });

      test('should parse time correctly', () {
        final time = InputValidation.parseTime('12:30');
        expect(time, isNotNull);
        expect(time!.hour, equals(12));
        expect(time.minute, equals(30));
        
        expect(InputValidation.parseTime('invalid'), isNull);
        expect(InputValidation.parseTime(null), isNull);
      });

      test('should format time correctly', () {
        final time = TimeOfDay(hour: 12, minute: 30);
        expect(InputValidation.formatTime(time), equals('12:30'));
        
        final time2 = TimeOfDay(hour: 9, minute: 5);
        expect(InputValidation.formatTime(time2), equals('09:05'));
      });
    });

    group('Required Field Validation', () {
      test('should validate required fields', () {
        expect(InputValidation.isRequired('test'), isTrue);
        expect(InputValidation.isRequired('  test  '), isTrue); // With spaces
        expect(InputValidation.isRequired('a'), isTrue); // Single character
      });

      test('should reject empty required fields', () {
        expect(InputValidation.isRequired(''), isFalse);
        expect(InputValidation.isRequired('   '), isFalse); // Only spaces
        expect(InputValidation.isRequired(null), isFalse);
      });

      test('should provide required field error messages', () {
        expect(InputValidation.getRequiredError(''), equals('This field is required'));
        expect(InputValidation.getRequiredError('   '), equals('This field is required'));
        expect(InputValidation.getRequiredError(null), equals('This field is required'));
        expect(InputValidation.getRequiredError('test'), isNull);
      });
    });

    group('Custom Validation', () {
      test('should validate custom patterns', () {
        expect(InputValidation.matchesPattern('ABC123', r'^[A-Z]{3}[0-9]{3}$'), isTrue);
        expect(InputValidation.matchesPattern('abc123', r'^[A-Z]{3}[0-9]{3}$'), isFalse);
        expect(InputValidation.matchesPattern('ABC12', r'^[A-Z]{3}[0-9]{3}$'), isFalse);
      });

      test('should validate length constraints', () {
        expect(InputValidation.hasValidLength('test', 3, 5), isTrue);
        expect(InputValidation.hasValidLength('te', 3, 5), isFalse); // Too short
        expect(InputValidation.hasValidLength('testing', 3, 5), isFalse); // Too long
        expect(InputValidation.hasValidLength('', 3, 5), isFalse); // Empty
      });

      test('should validate numeric ranges', () {
        expect(InputValidation.isInRange(5, 1, 10), isTrue);
        expect(InputValidation.isInRange(0, 1, 10), isFalse); // Too low
        expect(InputValidation.isInRange(11, 1, 10), isFalse); // Too high
        expect(InputValidation.isInRange(1, 1, 10), isTrue); // At minimum
        expect(InputValidation.isInRange(10, 1, 10), isTrue); // At maximum
      });
    });
  });
}
