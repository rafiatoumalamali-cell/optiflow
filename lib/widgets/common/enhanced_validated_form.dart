import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/input_validation.dart';
import '../utils/production_config.dart';
import '../../utils/app_colors.dart';

/// Enhanced validated form widget with robust input validation
class EnhancedValidatedForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final List<FormFieldConfig> fields;
  final String? title;
  final String? subtitle;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;
  final bool isLoading;
  final String? submitButtonText;
  final String? cancelButtonText;
  final bool autoValidate;
  final EdgeInsets? padding;
  final CrossAxisAlignment crossAxisAlignment;
  final bool showProgressIndicator;
  final Map<String, String>? customErrorMessages;

  const EnhancedValidatedForm({
    super.key,
    required this.formKey,
    required this.fields,
    this.title,
    this.subtitle,
    this.onSubmit,
    this.onCancel,
    this.isLoading = false,
    this.submitButtonText,
    this.cancelButtonText,
    this.autoValidate = false,
    this.padding,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.showProgressIndicator = true,
    this.customErrorMessages,
  });

  @override
  State<EnhancedValidatedForm> createState() => _EnhancedValidatedFormState();
}

class _EnhancedValidatedFormState extends State<EnhancedValidatedForm> {
  final Map<String, String?> _errors = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeFocusNodes();
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    _focusNodes.forEach((key, focusNode) => focusNode.dispose());
    super.dispose();
  }

  void _initializeControllers() {
    for (final field in widget.fields) {
      _controllers[field.key] = TextEditingController(
        text: field.initialValue ?? '',
      );
      
      // Add text change listener for real-time validation
      if (widget.autoValidate) {
        _controllers[field.key]!.addListener(() {
          _validateField(field.key);
        });
      }
    }
  }

  void _initializeFocusNodes() {
    for (final field in widget.fields) {
      _focusNodes[field.key] = FocusNode();
      
      // Add focus listener for validation on focus loss
      _focusNodes[field.key]!.addListener(() {
        if (!_focusNodes[field.key]!.hasFocus) {
          _validateField(field.key);
        }
      });
    }
  }

  String? _validateField(String fieldKey) {
    final field = widget.fields.firstWhere((f) => f.key == fieldKey);
    final value = _controllers[fieldKey]?.text.trim();
    
    String? error;
    
    switch (field.validationType) {
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
        error = field.customValidator?.call(value);
        break;
    }
    
    // Use custom error messages if provided
    if (error != null && widget.customErrorMessages != null) {
      final customMessage = widget.customErrorMessages![fieldKey];
      if (customMessage != null) {
        error = customMessage;
      }
    }
    
    setState(() {
      _errors[fieldKey] = error;
    });
    
    return error;
  }

  bool _validateAllFields() {
    bool allValid = true;
    
    for (final field in widget.fields) {
      final error = _validateField(field.key);
      if (error != null) {
        allValid = false;
      }
    }
    
    return allValid;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting || widget.isLoading) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    // Validate all fields
    final allValid = _validateAllFields();
    
    if (allValid) {
      // Collect form data
      final formData = <String, String?>{};
      for (final field in widget.fields) {
        formData[field.key] = _controllers[field.key]?.text.trim();
      }
      
      // Call submit callback
      if (widget.onSubmit != null) {
        await widget.onSubmit!(formData);
      }
    }
    
    setState(() {
      _isSubmitting = false;
    });
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    }
  }

  void _clearField(String fieldKey) {
    _controllers[fieldKey]?.clear();
    setState(() {
      _errors[fieldKey] = null;
    });
  }

  void _formatField(String fieldKey) {
    final field = widget.fields.firstWhere((f) => f.key == fieldKey);
    final value = _controllers[fieldKey]?.text.trim();
    
    String? formattedValue;
    
    switch (field.validationType) {
      case ValidationType.email:
        // Email doesn't need formatting
        break;
      case ValidationType.phone:
        formattedValue = InputValidation.formatPhone(value);
        break;
      case ValidationType.name:
        formattedValue = InputValidation.formatName(value);
        break;
      case ValidationType.price:
        final price = InputValidation.parsePrice(value);
        if (price != null) {
          formattedValue = InputValidation.formatPrice(price);
        }
        break;
      case ValidationType.date:
        // Date formatting would require date picker
        break;
      case ValidationType.time:
        // Time formatting would require time picker
        break;
      default:
        break;
    }
    
    if (formattedValue != null && formattedValue != value) {
      _controllers[fieldKey]?.text = formattedValue;
      _validateField(fieldKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (widget.subtitle != null) ...[
          Text(
            widget.subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Form(
          key: widget.formKey,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...widget.fields.map((field) => _buildField(field)),
                const SizedBox(height: 24),
                _buildFormActions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(FormFieldConfig field) {
    final errorText = _errors[field.key];
    final hasError = errorText != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label
        if (field.label != null) ...[
          Text(
            field.label!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: hasError ? AppColors.errorRed : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Field input
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? AppColors.errorRed : AppColors.textLight.withOpacity(0.3),
              width: hasError ? 2 : 1,
            ),
          ),
          child: _buildInputField(field, hasError),
        ),
        
        // Error message
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.errorRed,
            ),
          ),
        ],
        
        // Helper text
        if (field.helperText != null) ...[
          const SizedBox(height: 8),
          Text(
            field.helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
        
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInputField(FormFieldConfig field, bool hasError) {
    switch (field.inputType) {
      case FormInputType.text:
        return TextFormField(
          controller: _controllers[field.key],
          focusNode: _focusNodes[field.key],
          keyboardType: field.keyboardType,
          textCapitalization: field.textCapitalization,
          obscureText: field.obscureText,
          maxLength: field.maxLength,
          enabled: field.enabled && !widget.isLoading,
          style: TextStyle(
            color: field.enabled ? AppColors.textDark : AppColors.textLight,
          ),
          decoration: InputDecoration(
            hintText: field.hintText,
            prefixIcon: field.prefixIcon != null ? Icon(field.prefixIcon!, size: 20) : null,
            suffixIcon: _buildSuffixIcon(field),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
        
      case FormInputType.dropdown:
        return DropdownButtonFormField<String>(
          value: _controllers[field.key]!.text.isEmpty ? field.initialValue : _controllers[field.key]!.text,
          focusNode: _focusNodes[field.key],
          items: field.dropdownItems ?? [],
          onChanged: (value) {
            _controllers[field.key]!.text = value ?? '';
            _validateField(field.key);
          },
          enabled: field.enabled && !widget.isLoading,
          decoration: InputDecoration(
            hintText: field.hintText,
            prefixIcon: field.prefixIcon != null ? Icon(field.prefixIcon!, size: 20) : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
        
      case FormInputType.multiline:
        return TextFormField(
          controller: _controllers[field.key],
          focusNode: _focusNodes[field.key],
          keyboardType: field.keyboardType,
          maxLines: field.maxLines,
          maxLength: field.maxLength,
          enabled: field.enabled && !widget.isLoading,
          style: TextStyle(
            color: field.enabled ? AppColors.textDark : AppColors.textLight,
          ),
          decoration: InputDecoration(
            hintText: field.hintText,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
        
      case FormInputType.number:
        return TextFormField(
          controller: _controllers[field.key],
          focusNode: _focusNodes[field.key],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: field.maxLength,
          enabled: field.enabled && !widget.isLoading,
          style: TextStyle(
            color: field.enabled ? AppColors.textDark : AppColors.textLight,
          ),
          decoration: InputDecoration(
            hintText: field.hintText,
            prefixIcon: field.prefixIcon != null ? Icon(field.prefixIcon!, size: 20) : null,
            suffixIcon: _buildNumberSuffixIcon(field),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
        
      case FormInputType.phone:
        return TextFormField(
          controller: _controllers[field.key],
          focusNode: _focusNodes[field.key],
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-\(\)]')),
          ],
          maxLength: field.maxLength,
          enabled: field.enabled && !widget.isLoading,
          style: TextStyle(
            color: field.enabled ? AppColors.textDark : AppColors.textLight,
          ),
          decoration: InputDecoration(
            hintText: field.hintText,
            prefixIcon: field.prefixIcon != null ? Icon(field.prefixIcon!, size: 20) : null,
            suffixIcon: _buildPhoneSuffixIcon(field),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
        
      case FormInputType.email:
        return TextFormField(
          controller: _controllers[field.key],
          focusNode: _focusNodes[field.key],
          keyboardType: TextInputType.emailAddress,
          enabled: field.enabled && !widget.isLoading,
          style: TextStyle(
            color: field.enabled ? AppColors.textDark : AppColors.textLight,
          ),
          decoration: InputDecoration(
            hintText: field.hintText,
            prefixIcon: field.prefixIcon != null ? Icon(field.prefixIcon!, size: 20) : null,
            suffixIcon: _buildEmailSuffixIcon(field),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
        
      case FormInputType.password:
        return TextFormField(
          controller: _controllers[field.key],
          focusNode: _focusNodes[field.key],
          obscureText: true,
          enabled: field.enabled && !widget.isLoading,
          style: TextStyle(
            color: field.enabled ? AppColors.textDark : AppColors.textLight,
          ),
          decoration: InputDecoration(
            hintText: field.hintText,
            prefixIcon: field.prefixIcon != null ? Icon(field.prefixIcon!, size: 20) : null,
            suffixIcon: _buildPasswordSuffixIcon(field),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
    }
  }

  Widget? _buildSuffixIcon(FormFieldConfig field) {
    if (field.showClearButton && _controllers[field.key]!.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear, color: AppColors.textLight),
        onPressed: () => _clearField(field.key),
        tooltip: 'Clear field',
      );
    }
    
    if (field.showFormatButton) {
      return IconButton(
        icon: const Icon(Icons.format_align_center, color: AppColors.textLight),
        onPressed: () => _formatField(field.key),
        tooltip: 'Format field',
      );
    }
    
    return null;
  }

  Widget? _buildNumberSuffixIcon(FormFieldConfig field) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (field.showClearButton && _controllers[field.key]!.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, color: AppColors.textLight),
            onPressed: () => _clearField(field.key),
            tooltip: 'Clear field',
          ),
        if (field.showFormatButton)
          IconButton(
            icon: const Icon(Icons.format_align_center, color: AppColors.textLight),
            onPressed: () => _formatField(field.key),
            tooltip: 'Format field',
          ),
      ],
    );
  }

  Widget? _buildPhoneSuffixIcon(FormFieldConfig field) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (field.showClearButton && _controllers[field.key]!.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, color: AppColors.textLight),
            onPressed: () => _clearField(field.key),
            tooltip: 'Clear field',
          ),
        if (field.showFormatButton)
          IconButton(
            icon: const Icon(Icons.format_align_center, color: AppColors.textLight),
            onPressed: () => _formatField(field.key),
            tooltip: 'Format phone number',
          ),
      ],
    );
  }

  Widget? _buildEmailSuffixIcon(FormFieldConfig field) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (field.showClearButton && _controllers[field.key]!.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, color: AppColors.textLight),
            onPressed: () => _clearField(field.key),
            tooltip: 'Clear field',
          ),
      ],
    );
  }

  Widget? _buildPasswordSuffixIcon(FormFieldConfig field) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (field.showClearButton && _controllers[field.key]!.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, color: AppColors.textLight),
            onPressed: () => _clearField(field.key),
            tooltip: 'Clear field',
          ),
        IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: AppColors.textLight),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
        ),
      ],
    );
  }

  Widget _buildFormActions() {
    return Row(
      children: [
        if (widget.onCancel != null) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting || widget.isLoading ? null : _handleCancel,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.textLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                widget.cancelButtonText ?? 'Cancel',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting || widget.isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: widget.showProgressIndicator && widget.isLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                : Text(
                    widget.submitButtonText ?? 'Submit',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Form field configuration
class FormFieldConfig {
  final String key;
  final ValidationType validationType;
  final FormInputType inputType;
  final String? label;
  final String? hintText;
  final String? initialValue;
  final IconData? prefixIcon;
  final bool enabled;
  final bool showClearButton;
  final bool showFormatButton;
  final int? maxLength;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization? textCapitalization;
  final bool obscureText;
  final String? helperText;
  final List<DropdownMenuItem<String>>? dropdownItems;
  final String? Function(String?)? customValidator;

  FormFieldConfig({
    required this.key,
    required this.validationType,
    required this.inputType,
    this.label,
    this.hintText,
    this.initialValue,
    this.prefixIcon,
    this.enabled = true,
    this.showClearButton = true,
    this.showFormatButton = false,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization,
    this.obscureText = false,
    this.helperText,
    this.dropdownItems,
    this.customValidator,
  });
}

/// Form input types
enum FormInputType {
  text,
  dropdown,
  multiline,
  number,
  phone,
  email,
  password,
}
