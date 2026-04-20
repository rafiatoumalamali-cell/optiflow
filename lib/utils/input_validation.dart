import 'dart:core';
import 'package:flutter/material.dart';

/// Comprehensive input validation utilities for OptiFlow app
class InputValidation {
  // Email validation
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  static String? getEmailError(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Phone number validation
  static final RegExp _phoneRegex = RegExp(
    r'^\+?[1-9]\d{1,14}$|^[1-9]\d{6,14}$',
  );

  static bool isValidPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return _phoneRegex.hasMatch(cleanPhone);
  }

  static String? getPhoneError(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Phone number is required';
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!_phoneRegex.hasMatch(cleanPhone)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String formatPhoneNumber(String phone) {
    if (!isValidPhoneNumber(phone)) return phone;
    
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Format for Niger numbers
    if (cleanPhone.startsWith('227') && cleanPhone.length == 11) {
      return '+227 ${cleanPhone.substring(3, 5)} ${cleanPhone.substring(5, 8)} ${cleanPhone.substring(8)}';
    }
    
    // Format for US numbers
    if (cleanPhone.length == 10) {
      return '+1 ${cleanPhone.substring(0, 3)}-${cleanPhone.substring(3, 6)}-${cleanPhone.substring(6)}';
    }
    
    // Return with + prefix if not present
    return cleanPhone.startsWith('+') ? cleanPhone : '+$cleanPhone';
  }

  // Password validation
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]',
  );

  static bool isValidPassword(String? password) {
    if (password == null || password.isEmpty) return false;
    if (password.length < 8) return false;
    return _passwordRegex.hasMatch(password);
  }

  static String? getPasswordError(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain lowercase letter';
    }
    if (!password.contains(RegExp(r'\d'))) {
      return 'Password must contain number';
    }
    if (!password.contains(RegExp(r'[@$!%*?&]'))) {
      return 'Password must contain special character';
    }
    return null;
  }

  static int getPasswordStrength(String? password) {
    if (password == null || password.isEmpty) return 0;
    
    int strength = 0;
    
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'\d'))) strength++;
    if (password.contains(RegExp(r'[@$!%*?&]'))) strength++;
    
    return strength;
  }

  static String getPasswordStrengthDescription(int strength) {
    switch (strength) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      case 5:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }

  // Name validation
  static final RegExp _nameRegex = RegExp(
    r'^[a-zA-Z\u00C0-\u024F\s\'\-]{2,100}$',
  );

  static bool isValidName(String? name) {
    if (name == null || name.isEmpty) return false;
    final trimmedName = name.trim();
    if (trimmedName.length < 2 || trimmedName.length > 100) return false;
    return _nameRegex.hasMatch(trimmedName);
  }

  static String? getNameError(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name is required';
    }
    final trimmedName = name.trim();
    if (trimmedName.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (trimmedName.length > 100) {
      return 'Name must be less than 100 characters';
    }
    if (!_nameRegex.hasMatch(trimmedName)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    return null;
  }

  static String formatName(String name) {
    if (!isValidName(name)) return name;
    
    final parts = name.trim().split(' ');
    final formattedParts = parts.map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    }).toList();
    
    return formattedParts.join(' ');
  }

  // Address validation
  static bool isValidAddress(String? address) {
    if (address == null || address.isEmpty) return false;
    final trimmedAddress = address.trim();
    return trimmedAddress.length >= 5 && trimmedAddress.length <= 500;
  }

  static String? getAddressError(String? address) {
    if (address == null || address.isEmpty) {
      return 'Address is required';
    }
    final trimmedAddress = address.trim();
    if (trimmedAddress.length < 5) {
      return 'Address must be at least 5 characters';
    }
    if (trimmedAddress.length > 500) {
      return 'Address must be less than 500 characters';
    }
    return null;
  }

  // Business name validation
  static final RegExp _businessNameRegex = RegExp(
    r'^[a-zA-Z0-9\s\'\-\.,&]{2,100}$',
  );

  static bool isValidBusinessName(String? businessName) {
    if (businessName == null || businessName.isEmpty) return false;
    final trimmedName = businessName.trim();
    if (trimmedName.length < 2 || trimmedName.length > 100) return false;
    return _businessNameRegex.hasMatch(trimmedName);
  }

  static String? getBusinessNameError(String? businessName) {
    if (businessName == null || businessName.isEmpty) {
      return 'Business name is required';
    }
    final trimmedName = businessName.trim();
    if (trimmedName.length < 2) {
      return 'Business name must be at least 2 characters';
    }
    if (trimmedName.length > 100) {
      return 'Business name must be less than 100 characters';
    }
    if (!_businessNameRegex.hasMatch(trimmedName)) {
      return 'Business name contains invalid characters';
    }
    return null;
  }

  // Vehicle registration validation
  static final RegExp _vehicleRegistrationRegex = RegExp(
    r'^[A-Za-z0-9\s\-]{3,20}$',
  );

  static bool isValidVehicleRegistration(String? registration) {
    if (registration == null || registration.isEmpty) return false;
    final trimmedRegistration = registration.trim();
    if (trimmedRegistration.length < 3 || trimmedRegistration.length > 20) return false;
    return _vehicleRegistrationRegex.hasMatch(trimmedRegistration);
  }

  static String? getVehicleRegistrationError(String? registration) {
    if (registration == null || registration.isEmpty) {
      return 'Vehicle registration is required';
    }
    final trimmedRegistration = registration.trim();
    if (trimmedRegistration.length < 3) {
      return 'Vehicle registration must be at least 3 characters';
    }
    if (trimmedRegistration.length > 20) {
      return 'Vehicle registration must be less than 20 characters';
    }
    if (!_vehicleRegistrationRegex.hasMatch(trimmedRegistration)) {
      return 'Vehicle registration contains invalid characters';
    }
    return null;
  }

  // Weight validation
  static bool isValidWeight(String? weight) {
    if (weight == null || weight.isEmpty) return false;
    final value = double.tryParse(weight);
    if (value == null) return false;
    return value > 0 && value < 5000; // Max 5000 kg
  }

  static String? getWeightError(String? weight) {
    if (weight == null || weight.isEmpty) {
      return 'Weight is required';
    }
    final value = double.tryParse(weight);
    if (value == null) {
      return 'Please enter a valid weight';
    }
    if (value <= 0) {
      return 'Weight must be greater than 0';
    }
    if (value >= 5000) {
      return 'Weight must be less than 5000 kg';
    }
    return null;
  }

  static double? parseWeight(String? weight) {
    if (weight == null || weight.isEmpty) return null;
    return double.tryParse(weight);
  }

  // Distance validation
  static bool isValidDistance(String? distance) {
    if (distance == null || distance.isEmpty) return false;
    final value = double.tryParse(distance);
    if (value == null) return false;
    return value > 0 && value < 500; // Max 500 km
  }

  static String? getDistanceError(String? distance) {
    if (distance == null || distance.isEmpty) {
      return 'Distance is required';
    }
    final value = double.tryParse(distance);
    if (value == null) {
      return 'Please enter a valid distance';
    }
    if (value <= 0) {
      return 'Distance must be greater than 0';
    }
    if (value >= 500) {
      return 'Distance must be less than 500 km';
    }
    return null;
  }

  static double? parseDistance(String? distance) {
    if (distance == null || distance.isEmpty) return null;
    return double.tryParse(distance);
  }

  // Price validation
  static bool isValidPrice(String? price) {
    if (price == null || price.isEmpty) return false;
    final value = double.tryParse(price);
    if (value == null) return false;
    return value > 0 && value < 999999; // Max 999,999
  }

  static String? getPriceError(String? price) {
    if (price == null || price.isEmpty) {
      return 'Price is required';
    }
    final value = double.tryParse(price);
    if (value == null) {
      return 'Please enter a valid price';
    }
    if (value <= 0) {
      return 'Price must be greater than 0';
    }
    if (value >= 999999) {
      return 'Price must be less than 999999';
    }
    return null;
  }

  static double? parsePrice(String? price) {
    if (price == null || price.isEmpty) return null;
    return double.tryParse(price);
  }

  static String formatPrice(double price) {
    return price.toStringAsFixed(2);
  }

  // Quantity validation
  static bool isValidQuantity(String? quantity) {
    if (quantity == null || quantity.isEmpty) return false;
    final value = int.tryParse(quantity);
    if (value == null) return false;
    return value > 0 && value < 10000; // Max 10,000
  }

  static String? getQuantityError(String? quantity) {
    if (quantity == null || quantity.isEmpty) {
      return 'Quantity is required';
    }
    final value = int.tryParse(quantity);
    if (value == null) {
      return 'Please enter a valid quantity';
    }
    if (value <= 0) {
      return 'Quantity must be greater than 0';
    }
    if (value >= 10000) {
      return 'Quantity must be less than 10000';
    }
    if (quantity.contains('.')) {
      return 'Quantity must be a whole number';
    }
    return null;
  }

  static int? parseQuantity(String? quantity) {
    if (quantity == null || quantity.isEmpty) return null;
    return int.tryParse(quantity);
  }

  // URL validation
  static final RegExp _urlRegex = RegExp(
    r'^https?:\/\/(?:[-\w.])+(?:\:[0-9]+)?(?:\/(?:[\w\/_.])*(?:\?(?:[\w&=%.])*)?(?:\#(?:[\w.])*)?)?$',
  );

  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return _urlRegex.hasMatch(url.trim());
  }

  static String? getUrlError(String? url) {
    if (url == null || url.isEmpty) {
      return 'URL is required';
    }
    if (!_urlRegex.hasMatch(url.trim())) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  // Date validation
  static final RegExp _dateRegex = RegExp(
    r'^\d{4}-\d{2}-\d{2}$',
  );

  static bool isValidDate(String? date) {
    if (date == null || date.isEmpty) return false;
    if (!_dateRegex.hasMatch(date)) return false;
    
    try {
      final parts = date.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      final dateTime = DateTime(year, month, day);
      return dateTime.year == year && 
             dateTime.month == month && 
             dateTime.day == day;
    } catch (e) {
      return false;
    }
  }

  static String? getDateError(String? date) {
    if (date == null || date.isEmpty) {
      return 'Date is required';
    }
    if (!_dateRegex.hasMatch(date)) {
      return 'Please use YYYY-MM-DD format';
    }
    if (!isValidDate(date)) {
      return 'Please enter a valid date';
    }
    return null;
  }

  static DateTime? parseDate(String? date) {
    if (!isValidDate(date)) return null;
    
    try {
      final parts = date!.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (e) {
      return null;
    }
  }

  static String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static bool isDateInRange(String date, String startDate, String endDate) {
    final dateObj = parseDate(date);
    final startObj = parseDate(startDate);
    final endObj = parseDate(endDate);
    
    if (dateObj == null || startObj == null || endObj == null) return false;
    
    return (dateObj.isAtSameMomentAs(startObj) || dateObj.isAfter(startObj)) &&
           (dateObj.isAtSameMomentAs(endObj) || dateObj.isBefore(endObj));
  }

  // Time validation
  static final RegExp _timeRegex = RegExp(
    r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$',
  );

  static bool isValidTime(String? time) {
    if (time == null || time.isEmpty) return false;
    return _timeRegex.hasMatch(time);
  }

  static String? getTimeError(String? time) {
    if (time == null || time.isEmpty) {
      return 'Time is required';
    }
    if (!_timeRegex.hasMatch(time)) {
      return 'Please use HH:MM format';
    }
    if (!isValidTime(time)) {
      return 'Please enter a valid time';
    }
    return null;
  }

  static TimeOfDay? parseTime(String? time) {
    if (!isValidTime(time)) return null;
    
    try {
      final parts = time!.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }

  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Required field validation
  static bool isRequired(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static String? getRequiredError(String? value) {
    if (!isRequired(value)) {
      return 'This field is required';
    }
    return null;
  }

  // Custom validation helpers
  static bool matchesPattern(String? value, String pattern) {
    if (value == null || value.isEmpty) return false;
    return RegExp(pattern).hasMatch(value);
  }

  static bool hasValidLength(String? value, int minLength, int maxLength) {
    if (value == null || value.isEmpty) return false;
    final length = value.length;
    return length >= minLength && length <= maxLength;
  }

  static bool isInRange(num value, num min, num max) {
    return value >= min && value <= max;
  }

  // Comprehensive validation for forms
  static Map<String, String?> validateForm(Map<String, String?> formData, Map<String, String> validationRules) {
    final errors = <String, String?>{};
    
    for (final entry in validationRules.entries) {
      final fieldName = entry.key;
      final rule = entry.value;
      final value = formData[fieldName];
      
      switch (rule) {
        case 'required':
          errors[fieldName] = getRequiredError(value);
          break;
        case 'email':
          errors[fieldName] = getEmailError(value);
          break;
        case 'phone':
          errors[fieldName] = getPhoneError(value);
          break;
        case 'password':
          errors[fieldName] = getPasswordError(value);
          break;
        case 'name':
          errors[fieldName] = getNameError(value);
          break;
        case 'address':
          errors[fieldName] = getAddressError(value);
          break;
        case 'business_name':
          errors[fieldName] = getBusinessNameError(value);
          break;
        case 'vehicle_registration':
          errors[fieldName] = getVehicleRegistrationError(value);
          break;
        case 'weight':
          errors[fieldName] = getWeightError(value);
          break;
        case 'distance':
          errors[fieldName] = getDistanceError(value);
          break;
        case 'price':
          errors[fieldName] = getPriceError(value);
          break;
        case 'quantity':
          errors[fieldName] = getQuantityError(value);
          break;
        case 'url':
          errors[fieldName] = getUrlError(value);
          break;
        case 'date':
          errors[fieldName] = getDateError(value);
          break;
        case 'time':
          errors[fieldName] = getTimeError(value);
          break;
        default:
          // Handle custom rules
          if (rule.startsWith('min_length:')) {
            final minLength = int.parse(rule.split(':')[1]);
            errors[fieldName] = hasValidLength(value, minLength, 1000) ? null : 'Must be at least $minLength characters';
          } else if (rule.startsWith('max_length:')) {
            final maxLength = int.parse(rule.split(':')[1]);
            errors[fieldName] = hasValidLength(value, 0, maxLength) ? null : 'Must be less than $maxLength characters';
          }
      }
    }
    
    return errors;
  }

  // Batch validation
  static bool validateAll(Map<String, String?> formData, Map<String, String> validationRules) {
    final errors = validateForm(formData, validationRules);
    return errors.values.every((error) => error == null);
  }

  // Sanitization helpers
  static String sanitizeString(String? value) {
    if (value == null) return '';
    return value.trim();
  }

  static String sanitizePhone(String? phone) {
    if (phone == null) return '';
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  static String sanitizeNumber(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'[^\d.]'), '');
  }

  // Validation result class
  static ValidationResult validateField(String value, ValidationRule rule) {
    switch (rule.type) {
      case ValidationType.required:
        return ValidationResult(
          isValid: isRequired(value),
          error: getRequiredError(value),
        );
      case ValidationType.email:
        return ValidationResult(
          isValid: isValidEmail(value),
          error: getEmailError(value),
        );
      case ValidationType.phone:
        return ValidationResult(
          isValid: isValidPhoneNumber(value),
          error: getPhoneError(value),
        );
      case ValidationType.password:
        return ValidationResult(
          isValid: isValidPassword(value),
          error: getPasswordError(value),
        );
      case ValidationType.name:
        return ValidationResult(
          isValid: isValidName(value),
          error: getNameError(value),
        );
      case ValidationType.address:
        return ValidationResult(
          isValid: isValidAddress(value),
          error: getAddressError(value),
        );
      case ValidationType.businessName:
        return ValidationResult(
          isValid: isValidBusinessName(value),
          error: getBusinessNameError(value),
        );
      case ValidationType.vehicleRegistration:
        return ValidationResult(
          isValid: isValidVehicleRegistration(value),
          error: getVehicleRegistrationError(value),
        );
      case ValidationType.weight:
        return ValidationResult(
          isValid: isValidWeight(value),
          error: getWeightError(value),
        );
      case ValidationType.distance:
        return ValidationResult(
          isValid: isValidDistance(value),
          error: getDistanceError(value),
        );
      case ValidationType.price:
        return ValidationResult(
          isValid: isValidPrice(value),
          error: getPriceError(value),
        );
      case ValidationType.quantity:
        return ValidationResult(
          isValid: isValidQuantity(value),
          error: getQuantityError(value),
        );
      case ValidationType.url:
        return ValidationResult(
          isValid: isValidUrl(value),
          error: getUrlError(value),
        );
      case ValidationType.date:
        return ValidationResult(
          isValid: isValidDate(value),
          error: getDateError(value),
        );
      case ValidationType.time:
        return ValidationResult(
          isValid: isValidTime(value),
          error: getTimeError(value),
        );
      case ValidationType.custom:
        return ValidationResult(
          isValid: rule.customValidator?.call(value) ?? false,
          error: rule.errorMessage,
        );
    }
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({
    required this.isValid,
    this.error,
  });
}

/// Validation rule class
class ValidationRule {
  final ValidationType type;
  final String? errorMessage;
  final bool Function(String?)? customValidator;

  ValidationRule({
    required this.type,
    this.errorMessage,
    this.customValidator,
  });
}

/// Validation types enum
enum ValidationType {
  required,
  email,
  phone,
  password,
  name,
  address,
  businessName,
  vehicleRegistration,
  weight,
  distance,
  price,
  quantity,
  url,
  date,
  time,
  custom,
}
