import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/input_validation.dart';
import '../../utils/app_colors.dart';

/// A text field widget with built-in validation
class ValidatedTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final String? helperText;
  final String? initialValue;
  final ValidationType validationType;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Function(bool)? onFocusChanged;
  final Function(String?)? onValidationChanged;
  final String? Function(String?)? customValidator;
  final String? errorMessage;
  final Duration debounceTime;
  final String? semanticsLabel;
  final int? maxLines;
  final int? minLines;
  final TextEditingController? controller;

  const ValidatedTextField({
    super.key,
    required this.label,
    this.hintText,
    this.helperText,
    this.initialValue,
    required this.validationType,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.onValidationChanged,
    this.customValidator,
    this.errorMessage,
    this.debounceTime = const Duration(milliseconds: 300),
    this.semanticsLabel,
    this.maxLines = 1,
    this.minLines,
    this.controller,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String? _errorText;
  bool _obscureText = false;
  Timer? _debounceTimer;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _obscureText = widget.obscureText;
    
    // Set initial validation state
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _validateField(widget.initialValue!);
    }
    
    // Set up keyboard type based on validation type
    if (widget.keyboardType == null) {
      _setupDefaultKeyboardType();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _setupDefaultKeyboardType() {
    switch (widget.validationType) {
      case ValidationType.email:
        _controller.keyboardType = TextInputType.emailAddress;
        break;
      case ValidationType.phone:
        _controller.keyboardType = TextInputType.phone;
        break;
      case ValidationType.weight:
      case ValidationType.distance:
      case ValidationType.price:
        _controller.keyboardType = TextInputType.numberWithOptions(decimal: true);
        break;
      case ValidationType.quantity:
        _controller.keyboardType = TextInputType.number;
        break;
      case ValidationType.url:
        _controller.keyboardType = TextInputType.url;
        break;
      default:
        _controller.keyboardType = TextInputType.text;
    }
  }

  void _validateField(String value) {
    String? error;
    
    switch (widget.validationType) {
      case ValidationType.required:
        error = InputValidation.getRequiredError(value);
        break;
      case ValidationType.email:
        error = InputValidation.getEmailError(value);
        break;
      case ValidationType.phone:
        error = InputValidation.getPhoneError(value);
        break;
      case ValidationType.password:
        error = InputValidation.getPasswordError(value);
        break;
      case ValidationType.name:
        error = InputValidation.getNameError(value);
        break;
      case ValidationType.address:
        error = InputValidation.getAddressError(value);
        break;
      case ValidationType.businessName:
        error = InputValidation.getBusinessNameError(value);
        break;
      case ValidationType.vehicleRegistration:
        error = InputValidation.getVehicleRegistrationError(value);
        break;
      case ValidationType.weight:
        error = InputValidation.getWeightError(value);
        break;
      case ValidationType.distance:
        error = InputValidation.getDistanceError(value);
        break;
      case ValidationType.price:
        error = InputValidation.getPriceError(value);
        break;
      case ValidationType.quantity:
        error = InputValidation.getQuantityError(value);
        break;
      case ValidationType.url:
        error = InputValidation.getUrlError(value);
        break;
      case ValidationType.date:
        error = InputValidation.getDateError(value);
        break;
      case ValidationType.time:
        error = InputValidation.getTimeError(value);
        break;
      case ValidationType.custom:
        if (widget.customValidator != null) {
          final isValid = widget.customValidator!(value);
          error = isValid ? null : (widget.errorMessage ?? 'Invalid input');
        }
        break;
    }
    
    setState(() {
      _errorText = error;
    });
    
    widget.onValidationChanged?.call(error);
  }

  void _onChanged(String value) {
    _hasInteracted = true;
    
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    // Set up new debounce timer
    _debounceTimer = Timer(widget.debounceTime, () {
      _validateField(value);
    });
    
    widget.onChanged?.call(value);
  }

  void _onSubmitted(String value) {
    _validateField(value);
    widget.onSubmitted?.call(value);
  }

  void _onFocusChanged(bool hasFocus) {
    if (!hasFocus && _hasInteracted) {
      _validateField(_controller.text);
    }
    widget.onFocusChanged?.call(hasFocus);
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: widget.enabled ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        const SizedBox(height: 8),
        
        // Text field
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          obscureText: _obscureText,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          decoration: InputDecoration(
            hintText: widget.hintText,
            helperText: widget.helperText,
            errorText: _hasInteracted ? _errorText : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.textLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _errorText != null ? AppColors.errorRed : AppColors.textLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _errorText != null ? AppColors.errorRed : AppColors.primaryGreen,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
            ),
            filled: !widget.enabled,
            fillColor: widget.enabled ? null : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: _buildSuffixIcon(),
          ),
          onChanged: _onChanged,
          onFieldSubmitted: _onSubmitted,
          onTap: () => _hasInteracted = true,
          validator: (value) {
            _hasInteracted = true;
            _validateField(value ?? '');
            return _errorText;
          },
          semanticsLabel: widget.semanticsLabel,
        ),
        
        // Additional helper text if needed
        if (widget.validationType == ValidationType.password && _controller.text.isNotEmpty)
          _buildPasswordStrengthIndicator(),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    // Password visibility toggle
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textLight,
        ),
        onPressed: _togglePasswordVisibility,
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      );
    }
    
    // Clear button for non-required fields
    if (widget.validationType != ValidationType.required && _controller.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(
          Icons.clear,
          color: AppColors.textLight,
        ),
        onPressed: () {
          _controller.clear();
          _onChanged('');
        },
        tooltip: 'Clear field',
      );
    }
    
    return null;
  }

  Widget? _buildPasswordStrengthIndicator() {
    if (widget.validationType != ValidationType.password) return null;
    
    final strength = InputValidation.getPasswordStrength(_controller.text);
    final strengthDescription = InputValidation.getPasswordStrengthDescription(strength);
    
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          // Strength indicator bar
          Expanded(
            child: LinearProgressIndicator(
              value: strength / 5.0,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor(strength)),
              minHeight: 4,
            ),
          ),
          const SizedBox(width: 8),
          // Strength text
          Text(
            strengthDescription,
            style: TextStyle(
              fontSize: 12,
              color: _getStrengthColor(strength),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return AppColors.errorRed;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.lightGreen;
      case 5:
        return AppColors.successGreen;
      default:
        return Colors.grey;
    }
  }
}

/// A form field widget with validation for business forms
class ValidatedFormField extends StatelessWidget {
  final String label;
  final String? hintText;
  final String? initialValue;
  final ValidationType validationType;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final Function(String?)? onValidationChanged;
  final String? Function(String?)? customValidator;
  final String? errorMessage;
  final Duration debounceTime;
  final String? semanticsLabel;
  final int? maxLines;
  final int? minLines;
  final TextEditingController? controller;

  const ValidatedFormField({
    super.key,
    required this.label,
    this.hintText,
    this.initialValue,
    required this.validationType,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onValidationChanged,
    this.customValidator,
    this.errorMessage,
    this.debounceTime = const Duration(milliseconds: 300),
    this.semanticsLabel,
    this.maxLines = 1,
    this.minLines,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ValidatedTextField(
      label: label,
      hintText: hintText,
      initialValue: initialValue,
      validationType: validationType,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onValidationChanged: onValidationChanged,
      customValidator: customValidator,
      errorMessage: errorMessage,
      debounceTime: debounceTime,
      semanticsLabel: semanticsLabel,
      maxLines: maxLines,
      minLines: minLines,
      controller: controller,
    );
  }
}

/// A dropdown field with validation
class ValidatedDropdownField<T> extends StatefulWidget {
  final String label;
  final String? hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValidationType validationType;
  final bool enabled;
  final Function(T?)? onChanged;
  final Function(T?)? onValidationChanged;
  final String? semanticsLabel;

  const ValidatedDropdownField({
    super.key,
    required this.label,
    this.hintText,
    this.value,
    required this.items,
    required this.validationType,
    this.enabled = true,
    this.onChanged,
    this.onValidationChanged,
    this.semanticsLabel,
  });

  @override
  State<ValidatedDropdownField<T>> createState() => _ValidatedDropdownFieldState<T>();
}

class _ValidatedDropdownFieldState<T> extends State<ValidatedDropdownField<T>> {
  String? _errorText;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _validateField(widget.value.toString());
    }
  }

  void _validateField(String value) {
    String? error;
    
    switch (widget.validationType) {
      case ValidationType.required:
        error = InputValidation.getRequiredError(value);
        break;
      default:
        error = null;
    }
    
    setState(() {
      _errorText = error;
    });
    
    widget.onValidationChanged?.call(error);
  }

  void _onChanged(T? value) {
    _hasInteracted = true;
    _validateField(value?.toString() ?? '');
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: widget.enabled ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        const SizedBox(height: 8),
        
        // Dropdown field
        DropdownButtonFormField<T>(
          value: widget.value,
          items: widget.items,
          onChanged: widget.enabled ? _onChanged : null,
          decoration: InputDecoration(
            hintText: widget.hintText,
            errorText: _hasInteracted ? _errorText : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.textLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _errorText != null ? AppColors.errorRed : AppColors.textLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _errorText != null ? AppColors.errorRed : AppColors.primaryGreen,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
            ),
            filled: !widget.enabled,
            fillColor: widget.enabled ? null : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            _hasInteracted = true;
            _validateField(value?.toString() ?? '');
            return _errorText;
          },
          semanticsLabel: widget.semanticsLabel,
        ),
      ],
    );
  }
}

/// A date picker field with validation
class ValidatedDateField extends StatefulWidget {
  final String label;
  final String? hintText;
  final DateTime? initialValue;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValidationType validationType;
  final bool enabled;
  final Function(DateTime?)? onChanged;
  final Function(String?)? onValidationChanged;
  final String? semanticsLabel;

  const ValidatedDateField({
    super.key,
    required this.label,
    this.hintText,
    this.initialValue,
    this.firstDate,
    this.lastDate,
    required this.validationType,
    this.enabled = true,
    this.onChanged,
    this.onValidationChanged,
    this.semanticsLabel,
  });

  @override
  State<ValidatedDateField> createState() => _ValidatedDateFieldState();
}

class _ValidatedDateFieldState extends State<ValidatedDateField> {
  late TextEditingController _controller;
  String? _errorText;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue != null 
          ? InputValidation.formatDate(widget.initialValue!)
          : '',
    );
    
    if (widget.initialValue != null) {
      _validateField(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateField(String value) {
    String? error;
    
    switch (widget.validationType) {
      case ValidationType.date:
        error = InputValidation.getDateError(value);
        break;
      case ValidationType.required:
        error = InputValidation.getRequiredError(value);
        break;
      default:
        error = null;
    }
    
    setState(() {
      _errorText = error;
    });
    
    widget.onValidationChanged?.call(error);
  }

  Future<void> _selectDate() async {
    if (!widget.enabled) return;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.initialValue ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2100),
    );
    
    if (picked != null) {
      _hasInteracted = true;
      final formattedDate = InputValidation.formatDate(picked);
      _controller.text = formattedDate;
      _validateField(formattedDate);
      widget.onChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: widget.enabled ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        const SizedBox(height: 8),
        
        // Date field
        TextFormField(
          controller: _controller,
          enabled: widget.enabled,
          readOnly: true,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'YYYY-MM-DD',
            errorText: _hasInteracted ? _errorText : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.textLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _errorText != null ? AppColors.errorRed : AppColors.textLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _errorText != null ? AppColors.errorRed : AppColors.primaryGreen,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
            ),
            filled: !widget.enabled,
            fillColor: widget.enabled ? null : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: Icon(
              Icons.calendar_today,
              color: widget.enabled ? AppColors.primaryGreen : AppColors.textLight,
            ),
          ),
          onTap: _selectDate,
          validator: (value) {
            _hasInteracted = true;
            _validateField(value ?? '');
            return _errorText;
          },
          semanticsLabel: widget.semanticsLabel,
        ),
      ],
    );
  }
}
