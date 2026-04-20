import 'package:flutter/material.dart';
import '../utils/input_validation.dart';
import '../utils/production_config.dart';
import '../../utils/app_colors.dart';

/// Enhanced form validator with comprehensive validation rules
class EnhancedFormValidator {
  final Map<String, ValidationRule> _rules = {};
  final Map<String, String?> _errors = {};

  /// Add validation rule for a field
  void addRule(String fieldKey, ValidationRule rule) {
    _rules[fieldKey] = rule;
  }

  /// Remove validation rule for a field
  void removeRule(String fieldKey) {
    _rules.remove(fieldKey);
    _errors.remove(fieldKey);
  }

  /// Validate a single field
  String? validateField(String fieldKey, String? value) {
    final rule = _rules[fieldKey];
    if (rule == null) return null;

    final trimmedValue = value?.trim() ?? '';
    String? error;

    // Check required first
    if (rule.required && trimmedValue.isEmpty) {
      error = rule.requiredMessage ?? 'This field is required';
    } else if (trimmedValue.isNotEmpty) {
      // Apply validation rules only if field has content
      error = _applyValidationRules(trimmedValue, rule);
    }

    _errors[fieldKey] = error;
    return error;
  }

  /// Apply validation rules to a value
  String? _applyValidationRules(String value, ValidationRule rule) {
    // Length validation
    if (rule.minLength != null && value.length < rule.minLength!) {
      return rule.minLengthMessage ?? 'Must be at least ${rule.minLength} characters';
    }

    if (rule.maxLength != null && value.length > rule.maxLength!) {
      return rule.maxLengthMessage ?? 'Must be at most ${rule.maxLength} characters';
    }

    // Pattern validation
    if (rule.pattern != null && !rule.pattern!.hasMatch(value)) {
      return rule.patternMessage ?? 'Invalid format';
    }

    // Custom validation
    if (rule.customValidator != null) {
      final customError = rule.customValidator!(value);
      if (customError != null) {
        return customError;
      }
    }

    // Type-specific validation
    switch (rule.type) {
      case ValidationFieldType.email:
        return InputValidation.getEmailError(value);
      case ValidationFieldType.phone:
        return InputValidation.getPhoneError(value);
      case ValidationFieldType.password:
        return InputValidation.getPasswordError(value);
      case ValidationFieldType.name:
        return InputValidation.getNameError(value);
      case ValidationFieldType.address:
        return InputValidation.getAddressError(value);
      case ValidationFieldType.businessName:
        return InputValidation.getBusinessNameError(value);
      case ValidationFieldType.vehicleRegistration:
        return InputValidation.getVehicleRegistrationError(value);
      case ValidationFieldType.weight:
        return InputValidation.getWeightError(value);
      case ValidationFieldType.distance:
        return InputValidation.getDistanceError(value);
      case ValidationFieldType.price:
        return InputValidation.getPriceError(value);
      case ValidationFieldType.quantity:
        return InputValidation.getQuantityError(value);
      case ValidationFieldType.url:
        return InputValidation.getUrlError(value);
      case ValidationFieldType.date:
        return InputValidation.getDateError(value);
      case ValidationFieldType.time:
        return InputValidation.getTimeError(value);
      case ValidationFieldType.numeric:
        return _validateNumeric(value, rule);
      case ValidationFieldType.alpha:
        return _validateAlpha(value, rule);
      case ValidationFieldType.alphaNumeric:
        return _validateAlphaNumeric(value, rule);
      case ValidationFieldType.custom:
        // Handled by custom validator
        break;
    }

    return null;
  }

  /// Validate numeric field
  String? _validateNumeric(String value, ValidationRule rule) {
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    final numValue = double.parse(value);

    if (rule.minValue != null && numValue < rule.minValue!) {
      return 'Must be at least ${rule.minValue}';
    }

    if (rule.maxValue != null && numValue > rule.maxValue!) {
      return 'Must be at most ${rule.maxValue}';
    }

    return null;
  }

  /// Validate alpha field
  String? _validateAlpha(String value, ValidationRule rule) {
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Only letters and spaces are allowed';
    }
    return null;
  }

  /// Validate alpha-numeric field
  String? _validateAlphaNumeric(String value, ValidationRule rule) {
    if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(value)) {
      return 'Only letters, numbers, and spaces are allowed';
    }
    return null;
  }

  /// Validate all fields
  bool validateAll(Map<String, String?> formData) {
    bool allValid = true;

    for (final entry in formData.entries) {
      final error = validateField(entry.key, entry.value);
      if (error != null) {
        allValid = false;
      }
    }

    return allValid;
  }

  /// Get error for a field
  String? getError(String fieldKey) {
    return _errors[fieldKey];
  }

  /// Get all errors
  Map<String, String?> getAllErrors() {
    return Map.from(_errors);
  }

  /// Clear error for a field
  void clearError(String fieldKey) {
    _errors[fieldKey] = null;
  }

  /// Clear all errors
  void clearAllErrors() {
    _errors.clear();
  }

  /// Check if form has errors
  bool hasErrors() {
    return _errors.values.any((error) => error != null);
  }

  /// Check if field has error
  bool fieldHasError(String fieldKey) {
    return _errors[fieldKey] != null;
  }

  /// Get validation summary
  Map<String, dynamic> getValidationSummary() {
    return {
      'total_fields': _rules.length,
      'fields_with_errors': _errors.values.where((e) => e != null).length,
      'errors': _errors,
      'has_errors': hasErrors(),
      'rules_count': _rules.length,
    };
  }

  /// Dispose validator
  void dispose() {
    _rules.clear();
    _errors.clear();
  }
}

/// Validation rule configuration
class ValidationRule {
  final ValidationFieldType type;
  final bool required;
  final int? minLength;
  final int? maxLength;
  final double? minValue;
  final double? maxValue;
  final RegExp? pattern;
  final String? Function(String)? customValidator;
  final String? requiredMessage;
  final String? minLengthMessage;
  final String? maxLengthMessage;
  final String? minValueMessage;
  final String? maxValueMessage;
  final String? patternMessage;
  final bool sanitizeInput;
  final bool preventXSS;
  final bool preventSQLInjection;

  ValidationRule({
    required this.type,
    this.required = false,
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.pattern,
    this.customValidator,
    this.requiredMessage,
    this.minLengthMessage,
    this.maxLengthMessage,
    this.minValueMessage,
    this.maxValueMessage,
    this.patternMessage,
    this.sanitizeInput = true,
    this.preventXSS = true,
    this.preventSQLInjection = true,
  });

  /// Create required field rule
  factory ValidationRule.required({
    required ValidationFieldType type,
    String? message,
    int? minLength,
    int? maxLength,
    double? minValue,
    double? maxValue,
    RegExp? pattern,
    String? Function(String)? customValidator,
  }) {
    return ValidationRule(
      type: type,
      required: true,
      requiredMessage: message,
      minLength: minLength,
      maxLength: maxLength,
      minValue: minValue,
      maxValue: maxValue,
      pattern: pattern,
      customValidator: customValidator,
    );
  }

  /// Create email validation rule
  factory ValidationRule.email({
    bool required = false,
    String? message,
  }) {
    return ValidationRule(
      type: ValidationFieldType.email,
      required: required,
      requiredMessage: message,
    );
  }

  /// Create phone validation rule
  factory ValidationRule.phone({
    bool required = false,
    String? message,
  }) {
    return ValidationRule(
      type: ValidationFieldType.phone,
      required: required,
      requiredMessage: message,
    );
  }

  /// Create password validation rule
  factory ValidationRule.password({
    bool required = false,
    String? message,
    int? minLength,
  }) {
    return ValidationRule(
      type: ValidationFieldType.password,
      required: required,
      requiredMessage: message,
      minLength: minLength ?? 8,
    );
  }

  /// Create name validation rule
  factory ValidationRule.name({
    bool required = false,
    String? message,
    int? minLength,
    int? maxLength,
  }) {
    return ValidationRule(
      type: ValidationFieldType.name,
      required: required,
      requiredMessage: message,
      minLength: minLength ?? 2,
      maxLength: maxLength ?? 50,
    );
  }

  /// Create numeric validation rule
  factory ValidationRule.numeric({
    bool required = false,
    String? message,
    double? minValue,
    double? maxValue,
  }) {
    return ValidationRule(
      type: ValidationFieldType.numeric,
      required: required,
      requiredMessage: message,
      minValue: minValue,
      maxValue: maxValue,
    );
  }

  /// Create custom validation rule
  factory ValidationRule.custom({
    required String Function(String) validator,
    bool required = false,
    String? message,
  }) {
    return ValidationRule(
      type: ValidationFieldType.custom,
      required: required,
      requiredMessage: message,
      customValidator: validator,
    );
  }

  /// Sanitize input value
  String sanitize(String value) {
    if (!sanitizeInput) return value;

    var sanitized = value.trim();

    // Prevent XSS
    if (preventXSS) {
      sanitized = sanitized
          .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<[^>]*>', caseSensitive: false), '');
    }

    // Prevent SQL injection
    if (preventSQLInjection) {
      sanitized = sanitized
          .replaceAll(RegExp(r"([';--]|(/\*|\*/)|(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b)", caseSensitive: false), '');
    }

    return sanitized;
  }
}

/// Validation field types
enum ValidationFieldType {
  text,
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
  numeric,
  alpha,
  alphaNumeric,
  custom,
}

/// Enhanced form field with built-in validation
class EnhancedFormField extends StatefulWidget {
  final String fieldKey;
  final ValidationRule validationRule;
  final String? label;
  final String? hintText;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final VoidCallback? onChanged;
  final VoidCallback? onEditingComplete;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool showClearButton;
  final bool showFormatButton;
  final VoidCallback? onClear;
  final VoidCallback? onFormat;

  const EnhancedFormField({
    super.key,
    required this.fieldKey,
    required this.validationRule,
    this.label,
    this.hintText,
    this.initialValue,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.onChanged,
    this.onEditingComplete,
    this.validator,
    this.controller,
    this.focusNode,
    this.showClearButton = true,
    this.showFormatButton = false,
    this.onClear,
    this.onFormat,
  });

  @override
  State<EnhancedFormField> createState() => _EnhancedFormFieldState();
}

class _EnhancedFormFieldState extends State<EnhancedFormField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String? _error;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText;

    // Add listeners
    _controller.addListener(_onChanged);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _focusNode.removeListener(_onFocusChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    final value = _controller.text;
    final sanitizedValue = widget.validationRule.sanitize(value);
    
    if (value != sanitizedValue) {
      _controller.value = TextEditingValue(
        text: sanitizedValue,
        selection: _controller.selection,
      );
    }
    
    widget.onChanged?.call();
    
    // Validate on change if enabled
    if (!ProductionConfig.isProduction) {
      _validateField();
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _validateField();
    }
  }

  void _validateField() {
    final validator = widget.validator ?? EnhancedFormValidator();
    final error = validator(_controller.text);
    
    setState(() {
      _error = error;
    });
  }

  void _clearField() {
    _controller.clear();
    widget.onClear?.call();
    _validateField();
  }

  void _formatField() {
    widget.onFormat?.call();
    _validateField();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              color: hasError ? AppColors.errorRed : AppColors.textDark,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? AppColors.errorRed : AppColors.textLight.withOpacity(0.3),
              width: hasError ? 2 : 1,
            ),
          ),
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText ? _obscureText : false,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            enabled: widget.enabled,
            style: TextStyle(
              color: widget.enabled ? AppColors.textDark : AppColors.textLight,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon!, size: 20) : null,
              suffixIcon: _buildSuffixIcon(),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              counterText: '',
            ),
            onChanged: (value) {
              // Sanitize input
              final sanitizedValue = widget.validationRule.sanitize(value);
              if (value != sanitizedValue) {
                _controller.value = TextEditingValue(
                  text: sanitizedValue,
                  selection: _controller.selection,
                );
              }
            },
            onEditingComplete: widget.onEditingComplete,
            validator: widget.validator ?? (value) {
              return _validateField();
            },
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            _error!,
            style: TextStyle(
              color: AppColors.errorRed,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    final widgets = <Widget>[];

    // Clear button
    if (widget.showClearButton && _controller.text.isNotEmpty) {
      widgets.add(
        IconButton(
          icon: const Icon(Icons.clear, color: AppColors.textLight),
          onPressed: _clearField,
          tooltip: 'Clear field',
        ),
      );
    }

    // Format button
    if (widget.showFormatButton) {
      widgets.add(
        IconButton(
          icon: const Icon(Icons.format_align_center, color: AppColors.textLight),
          onPressed: _formatField,
          tooltip: 'Format field',
        ),
      );
    }

    // Password visibility toggle
    if (widget.obscureText) {
      widgets.add(
        IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            color: AppColors.textLight,
          ),
          onPressed: _togglePasswordVisibility,
          tooltip: _obscureText ? 'Show password' : 'Hide password',
        ),
      );
    }

    // Custom suffix icon
    if (widget.suffixIcon != null) {
      widgets.add(widget.suffixIcon!);
    }

    return widgets.isEmpty ? null : Row(mainAxisSize: MainAxisSize.min, children: widgets);
  }
}
