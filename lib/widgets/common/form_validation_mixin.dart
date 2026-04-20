import 'package:flutter/material.dart';
import '../utils/input_validation.dart';

/// Mixin for form validation across all screens
mixin FormValidationMixin<T extends StatefulWidget> on State<T> {
  final Map<String, String?> _errors = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  bool _isSubmitting = false;

  /// Initialize form validation
  void initializeFormValidation(List<String> fieldKeys) {
    for (final key in fieldKeys) {
      _controllers[key] = TextEditingController();
      _focusNodes[key] = FocusNode();
      
      // Add listeners for real-time validation
      _controllers[key]!.addListener(() {
        validateField(key);
      });
      
      // Add focus listeners for validation on focus loss
      _focusNodes[key]!.addListener(() {
        if (!_focusNodes[key]!.hasFocus) {
          validateField(key);
        }
      });
    }
  }

  /// Dispose form validation resources
  void disposeFormValidation() {
    for (final key in _controllers.keys) {
      _controllers[key]?.removeListener(validateField);
      _controllers[key]?.dispose();
    }
    
    for (final key in _focusNodes.keys) {
      _focusNodes[key]?.removeListener(validateField);
      _focusNodes[key]?.dispose();
    }
    
    _errors.clear();
    _controllers.clear();
    _focusNodes.clear();
  }

  /// Validate a single field
  String? validateField(String fieldKey, {String? value}) {
    final textValue = value ?? _controllers[fieldKey]?.text?.trim() ?? '';
    
    String? error;
    
    // Use the existing InputValidation utility
    if (textValue.isEmpty) {
      error = 'This field is required';
    } else if (textValue.contains('test')) {
      error = 'Test values are not allowed in production';
    } else if (textValue.length > 100) {
      error = 'Field cannot exceed 100 characters';
    } else if (textValue.contains('<script>')) {
      error = 'Invalid characters detected';
    } else {
      // Additional validation based on field type
      // This would be expanded based on specific field requirements
      error = null;
    }
    
    setState(() {
      _errors[fieldKey] = error;
    });
    
    return error;
  }

  /// Validate email field
  String? validateEmail(String fieldKey, {String? value}) {
    final textValue = value ?? _controllers[fieldKey]?.text?.trim() ?? '';
    final error = InputValidation.getEmailError(textValue);
    
    setState(() {
      _errors[fieldKey] = error;
    });
    
    return error;
  }

  /// Validate phone field
  String? validatePhone(String fieldKey, {String? value}) {
    final textValue = value ?? _controllers[fieldKey]?.text?.trim() ?? '';
    final error = InputValidation.getPhoneError(textValue);
    
    setState(() {
      _errors[fieldKey] = error;
    });
    
    return error;
  }

  /// Validate password field
  String? validatePassword(String fieldKey, {String? value}) {
    final textValue = value ?? _controllers[fieldKey]?.text?.trim() ?? '';
    final error = InputValidation.getPasswordError(textValue);
    
    setState(() {
      _errors[fieldKey] = error;
    });
    
    return error;
  }

  /// Validate name field
  String? validateName(String fieldKey, {String? value}) {
    final textValue = value ?? _controllers[fieldKey]?.text?.trim() ?? '';
    final error = InputValidation.getNameError(textValue);
    
    setState(() {
      _errors[fieldKey] = error;
    });
    
    return error;
  }

  /// Validate required field
  String? validateRequired(String fieldKey, {String? value}) {
    final textValue = value ?? _controllers[fieldKey]?.text?.trim() ?? '';
    final error = InputValidation.getRequiredError(textValue);
    
    setState(() {
      _errors[fieldKey] = error;
    });
    
    return error;
  }

  /// Validate numeric field
  String? validateNumeric(String fieldKey, {String? value, double? min, double? max}) {
    final textValue = value ?? _controllers[fieldKey]?.text?.trim() ?? '';
    final numValue = double.tryParse(textValue);
    
    String? error;
    
    if (textValue.isEmpty) {
      error = 'This field is required';
    } else if (numValue == null) {
      error = 'Please enter a valid number';
    } else if (min != null && numValue! < min) {
      error = 'Value must be at least $min';
    } else if (max != null && numValue! > max) {
      error = 'Value must be at most $max';
    }
    
    setState(() {
      _errors[fieldKey] = error;
    });
    
    return error;
  }

  /// Validate length field
  String? validateLength(String fieldKey, {String? value, int? minLength, int? maxLength}) {
    final textValue = value ?? _controllers[fieldKey]?.text?.trim() ?? '';
    
    String? error;
    
    if (textValue.isEmpty) {
      error = 'This field is required';
    } else if (minLength != null && textValue.length < minLength) {
      error = 'Must be at least $minLength characters';
    } else if (maxLength != null && textValue.length > maxLength) {
      error = 'Must be at most $maxLength characters';
    }
    
    setState(() {
      _errors[fieldKey] = error;
    });
    
    return error;
  }

  /// Validate pattern field
  String? validatePattern(String fieldKey, {String? value, String? pattern, String? errorMessage}) {
    final textValue = value ?? _controllers[fieldKey]?.text?.trim() ?? '';
    final regex = RegExp(pattern ?? '');
    
    String? error;
    
    if (textValue.isEmpty) {
      error = 'This field is required';
    } else if (!regex.hasMatch(textValue)) {
      error = errorMessage ?? 'Invalid format';
    }
    
    setState(() {
      _errors[fieldKey] = error;
    });
    
    return error;
  }

  /// Validate all form fields
  bool validateAllFields(List<String> fieldKeys) {
    bool allValid = true;
    
    for (final key in fieldKeys) {
      final error = validateField(key);
      if (error != null) {
        allValid = false;
      }
    }
    
    return allValid;
  }

  /// Clear field error
  void clearFieldError(String fieldKey) {
    setState(() {
      _errors[fieldKey] = null;
    });
  }

  /// Clear all field errors
  void clearAllErrors() {
    setState(() {
      _errors.clear();
    });
  }

  /// Get field error
  String? getFieldError(String fieldKey) {
    return _errors[fieldKey];
  }

  /// Check if form has errors
  bool hasErrors() {
    return _errors.values.any((error) => error != null);
  }

  /// Get all errors
  Map<String, String?> getAllErrors() {
    return Map.from(_errors);
  }

  /// Set submitting state
  void setSubmittingState(bool isSubmitting) {
    setState(() {
      _isSubmitting = isSubmitting;
    });
  }

  /// Get submitting state
  bool isFormSubmitting() {
    return _isSubmitting;
  }

  /// Get field controller
  TextEditingController? getFieldController(String fieldKey) {
    return _controllers[fieldKey];
  }

  /// Get field focus node
  FocusNode? getFieldFocusNode(String fieldKey) {
    return _focusNodes[fieldKey];
  }

  /// Set field value
  void setFieldValue(String fieldKey, String value) {
    _controllers[fieldKey]?.text = value;
    validateField(fieldKey, value: value);
  }

  /// Get field value
  String getFieldValue(String fieldKey) {
    return _controllers[fieldKey]?.text ?? '';
  }

  /// Clear field
  void clearField(String fieldKey) {
    _controllers[fieldKey]?.clear();
    clearFieldError(fieldKey);
  }

  /// Clear all fields
  void clearAllFields() {
    for (final key in _controllers.keys) {
      _controllers[key]?.clear();
    }
    clearAllErrors();
  }

  /// Focus field
  void focusField(String fieldKey) {
    FocusScope.of(context).requestFocus(_focusNodes[fieldKey]!);
  }

  /// Unfocus field
  void unfocusField(String fieldKey) {
    _focusNodes[fieldKey]?.unfocus();
  }

  /// Validate and submit form
  Future<bool> validateAndSubmitForm(
    List<String> fieldKeys,
    Future<void> Function(Map<String, String>) onSubmit,
  ) async {
    final allValid = validateAllFields(fieldKeys);
    
    if (allValid) {
      setSubmittingState(true);
      
      try {
        final formData = <String, String>{};
        for (final key in fieldKeys) {
          formData[key] = getFieldValue(key);
        }
        
        await onSubmit(formData);
        return true;
      } catch (e) {
        // Handle submission error
        return false;
      } finally {
        setSubmittingState(false);
      }
    } else {
      return false;
    }
  }

  /// Build validated text field
  Widget buildValidatedTextField({
    required String fieldKey,
    String? label,
    String? hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    int? maxLines = 1,
    int? maxLength,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    bool enabled = true,
    TextCapitalization? textCapitalization,
  }) {
    final error = getFieldError(fieldKey);
    final hasError = error != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              color: hasError ? Colors.red : Colors.black87,
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
              color: hasError ? Colors.red : Colors.grey.shade300,
              width: hasError ? 2 : 1,
            ),
          ),
          child: TextFormField(
            controller: getFieldController(fieldKey),
            focusNode: getFieldFocusNode(fieldKey),
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: maxLines,
            maxLength: maxLength,
            enabled: enabled && !isFormSubmitting(),
            textCapitalization: textCapitalization,
            style: TextStyle(
              color: enabled ? Colors.black87 : Colors.grey.shade600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              errorText: hasError ? error : null,
              errorStyle: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
            onChanged: (value) {
              validateField(fieldKey, value: value);
            },
            validator: validator ?? (value) {
              return validateField(fieldKey, value: value);
            },
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  /// Build validated password field
  Widget buildValidatedPasswordField({
    required String fieldKey,
    String? label,
    String? hintText,
    int? maxLength,
    IconData? prefixIcon,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    final error = getFieldError(fieldKey);
    final hasError = error != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              color: hasError ? Colors.red : Colors.black87,
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
              color: hasError ? Colors.red : Colors.grey.shade300,
              width: hasError ? 2 : 1,
            ),
          ),
          child: TextFormField(
            controller: getFieldController(fieldKey),
            focusNode: getFieldFocusNode(fieldKey),
            obscureText: true,
            maxLength: maxLength,
            enabled: enabled && !isFormSubmitting(),
            style: TextStyle(
              color: enabled ? Colors.black87 : Colors.grey.shade600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              errorText: hasError ? error : null,
              errorStyle: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _controllers[fieldKey]!.text.isEmpty ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  // Toggle password visibility would be handled here
                },
              ),
            ),
            onChanged: (value) {
              validateField(fieldKey, value: value);
            },
            validator: validator ?? (value) {
              return validatePassword(fieldKey, value: value);
            },
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  /// Build validated dropdown field
  Widget buildValidatedDropdownField<T>({
    required String fieldKey,
    String? label,
    String? hintText,
    required List<DropdownMenuItem<T>> items,
    T? value,
    String? Function(T?)? validator,
    bool enabled = true,
  }) {
    final error = getFieldError(fieldKey);
    final hasError = error != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              color: hasError ? Colors.red : Colors.black87,
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
              color: hasError ? Colors.red : Colors.grey.shade300,
              width: hasError ? 2 : 1,
            ),
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: (T? newValue) {
              setFieldValue(fieldKey, newValue?.toString() ?? '');
            },
            validator: validator ?? (T? value) {
              return validateField(fieldKey, value: value?.toString());
            },
            enabled: enabled && !isFormSubmitting(),
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              errorText: hasError ? error : null,
              errorStyle: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  /// Build form submit button
  Widget buildSubmitButton({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool enabled = true,
  }) {
    return ElevatedButton(
      onPressed: (enabled && !isLoading && !isFormSubmitting()) ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? Colors.blue : Colors.grey.shade400,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Processing...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  /// Build form cancel button
  Widget buildCancelButton({
    required String text,
    VoidCallback? onPressed,
    bool enabled = true,
  }) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 16,
        ),
      ),
    );
  }
}
