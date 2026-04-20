import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// Localized error messages for all exception types
class LocalizedErrorMessages {
  static String getLocalizedErrorMessage(
    BuildContext context,
    String errorKey, {
    Map<String, dynamic>? parameters,
  }) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return _getFallbackMessage(errorKey);
    
    final locale = localizations.locale.languageCode;
    final errorMessages = _errorMessages[locale] ?? _errorMessages['en']!;
    
    String message = errorMessages[errorKey] ?? _getFallbackMessage(errorKey);
    
    // Replace parameters in message
    if (parameters != null) {
      parameters.forEach((key, value) {
        message = message.replaceAll('{$key}', value.toString());
      });
    }
    
    return message;
  }

  /// Get localized validation error message
  static String getValidationErrorMessage(
    BuildContext context,
    ValidationType validationType, {
    String? fieldName,
    dynamic value,
  }) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return _getValidationFallback(validationType);
    
    final locale = localizations.locale.languageCode;
    final validationMessages = _validationMessages[locale] ?? _validationMessages['en']!;
    
    String message = validationMessages[validationType.toString()] ?? _getValidationFallback(validationType);
    
    // Replace field name and value if provided
    if (fieldName != null) {
      message = message.replaceAll('{fieldName}', fieldName!);
    }
    if (value != null) {
      message = message.replaceAll('{value}', value.toString());
    }
    
    return message;
  }

  /// Get localized network error message
  static String getNetworkErrorMessage(
    BuildContext context,
    NetworkErrorType errorType, {
    String? url,
    int? statusCode,
  }) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return _getNetworkFallback(errorType);
    
    final locale = localizations.locale.languageCode;
    final networkMessages = _networkMessages[locale] ?? _networkMessages['en']!;
    
    String message = networkMessages[errorType.toString()] ?? _getNetworkFallback(errorType);
    
    // Replace parameters if provided
    if (url != null) {
      message = message.replaceAll('{url}', url!);
    }
    if (statusCode != null) {
      message = message.replaceAll('{statusCode}', statusCode.toString());
    }
    
    return message;
  }

  /// Get localized authentication error message
  static String getAuthenticationErrorMessage(
    BuildContext context,
    AuthErrorType errorType, {
    String? email,
    String? operation,
  }) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return _getAuthFallback(errorType);
    
    final locale = localizations.locale.languageCode;
    final authMessages = _authMessages[locale] ?? _authMessages['en']!;
    
    String message = authMessages[errorType.toString()] ?? _getAuthFallback(errorType);
    
    // Replace parameters if provided
    if (email != null) {
      message = message.replaceAll('{email}', email!);
    }
    if (operation != null) {
      message = message.replaceAll('{operation}', operation!);
    }
    
    return message;
  }

  /// Get localized database error message
  static String getDatabaseErrorMessage(
    BuildContext context,
    DatabaseErrorType errorType, {
    String? collection,
    String? documentId,
  }) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return _getDatabaseFallback(errorType);
    
    final locale = localizations.locale.languageCode;
    final databaseMessages = _databaseMessages[locale] ?? _databaseMessages['en']!;
    
    String message = databaseMessages[errorType.toString()] ?? _getDatabaseFallback(errorType);
    
    // Replace parameters if provided
    if (collection != null) {
      message = message.replaceAll('{collection}', collection!);
    }
    if (documentId != null) {
      message = message.replaceAll('{documentId}', documentId!);
    }
    
    return message;
  }

  /// Get localized storage error message
  static String getStorageErrorMessage(
    BuildContext context,
    StorageErrorType errorType, {
    String? fileName,
    String? operation,
  }) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return _getStorageFallback(errorType);
    
    final locale = localizations.locale.languageCode;
    final storageMessages = _storageMessages[locale] ?? _storageMessages['en']!;
    
    String message = storageMessages[errorType.toString()] ?? _getStorageFallback(errorType);
    
    // Replace parameters if provided
    if (fileName != null) {
      message = message.replaceAll('{fileName}', fileName!);
    }
    if (operation != null) {
      message = message.replaceAll('{operation}', operation!);
    }
    
    return message;
  }

  /// Get localized location error message
  static String getLocationErrorMessage(
    BuildContext context,
    LocationErrorType errorType, {
    String? operation,
  }) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return _getLocationFallback(errorType);
    
    final locale = localizations.locale.languageCode;
    final locationMessages = _locationMessages[locale] ?? _locationMessages['en']!;
    
    String message = locationMessages[errorType.toString()] ?? _getLocationFallback(errorType);
    
    // Replace parameters if provided
    if (operation != null) {
      message = message.replaceAll('{operation}', operation!);
    }
    
    return message;
  }

  /// Get localized maps error message
  static String getMapsErrorMessage(
    BuildContext context,
    MapsErrorType errorType, {
    String? operation,
    String? placeId,
  }) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return _getMapsFallback(errorType);
    
    final locale = localizations.locale.languageCode;
    final mapsMessages = _mapsMessages[locale] ?? _mapsMessages['en']!;
    
    String message = mapsMessages[errorType.toString()] ?? _getMapsFallback(errorType);
    
    // Replace parameters if provided
    if (operation != null) {
      message = message.replaceAll('{operation}', operation!);
    }
    if (placeId != null) {
      message = message.replaceAll('{placeId}', placeId!);
    }
    
    return message;
  }

  /// Get localized system error message
  static String getSystemErrorMessage(
    BuildContext context,
    SystemErrorType errorType, {
    String? operation,
    String? component,
  }) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return _getSystemFallback(errorType);
    
    final locale = localizations.locale.languageCode;
    final systemMessages = _systemMessages[locale] ?? _systemMessages['en']!;
    
    String message = systemMessages[errorType.toString()] ?? _getSystemFallback(errorType);
    
    // Replace parameters if provided
    if (operation != null) {
      message = message.replaceAll('{operation}', operation!);
    }
    if (component != null) {
      message = message.replaceAll('{component}', component!);
    }
    
    return message;
  }

  /// Get fallback message when localization is not available
  static String _getFallbackMessage(String errorKey) {
    final fallbackMessages = _errorMessages['en']!;
    return fallbackMessages[errorKey] ?? 'An error occurred. Please try again.';
  }

  /// Get validation fallback message
  static String _getValidationFallback(ValidationType validationType) {
    final fallbackMessages = _validationMessages['en']!;
    return fallbackMessages[validationType.toString()] ?? 'Invalid input. Please check your input and try again.';
  }

  /// Get network fallback message
  static String _getNetworkFallback(NetworkErrorType errorType) {
    final fallbackMessages = _networkMessages['en']!;
    return fallbackMessages[errorType.toString()] ?? 'Network error occurred. Please check your connection and try again.';
  }

  /// Get authentication fallback message
  static String _getAuthFallback(AuthErrorType errorType) {
    final fallbackMessages = _authMessages['en']!;
    return fallbackMessages[errorType.toString()] ?? 'Authentication error occurred. Please try again.';
  }

  /// Get database fallback message
  static String _getDatabaseFallback(DatabaseErrorType errorType) {
    final fallbackMessages = _databaseMessages['en']!;
    return fallbackMessages[errorType.toString()] ?? 'Database error occurred. Please try again.';
  }

  /// Get storage fallback message
  static String _getStorageFallback(StorageErrorType errorType) {
    final fallbackMessages = _storageMessages['en']!;
    return fallbackMessages[errorType.toString()] ?? 'Storage error occurred. Please try again.';
  }

  /// Get location fallback message
  static String _getLocationFallback(LocationErrorType errorType) {
    final fallbackMessages = _locationMessages['en']!;
    return fallbackMessages[errorType.toString()] ?? 'Location error occurred. Please try again.';
  }

  /// Get maps fallback message
  static String _getMapsFallback(MapsErrorType errorType) {
    final fallbackMessages = _mapsMessages['en']!;
    return fallbackMessages[errorType.toString()] ?? 'Maps error occurred. Please try again.';
  }

  /// Get system fallback message
  static String _getSystemFallback(SystemErrorType errorType) {
    final fallbackMessages = _systemMessages['en']!;
    return fallbackMessages[errorType.toString()] ?? 'System error occurred. Please try again.';
  }

  /// Error messages by language
  static const Map<String, Map<String, String>> _errorMessages = {
    'en': {
      'network_connection_failed': 'Network connection failed. Please check your internet connection and try again.',
      'network_timeout': 'Request timed out. Please try again.',
      'network_server_error': 'Server error occurred. Please try again later.',
      'network_not_found': 'The requested resource was not found.',
      'network_unauthorized': 'You are not authorized to access this resource.',
      'network_forbidden': 'You do not have permission to access this resource.',
      'network_too_many_requests': 'Too many requests. Please try again later.',
      'network_internal_error': 'Internal server error. Please try again later.',
      'network_service_unavailable': 'Service is temporarily unavailable. Please try again later.',
      'network_bad_gateway': 'Server gateway error. Please try again later.',
      'network_gateway_timeout': 'Gateway timeout. Please try again later.',
      'network_unknown_error': 'Unknown network error occurred. Please try again.',
      
      'auth_user_not_found': 'User not found. Please check your credentials.',
      'auth_wrong_password': 'Incorrect password. Please try again.',
      'auth_invalid_email': 'Invalid email address. Please check your email.',
      'auth_weak_password': 'Password is too weak. Please choose a stronger password.',
      'auth_email_already_in_use': 'Email is already in use. Please use a different email.',
      'auth_too_many_attempts': 'Too many failed attempts. Please try again later.',
      'auth_user_disabled': 'Account has been disabled. Please contact support.',
      'auth_operation_not_allowed': 'This operation is not allowed.',
      'auth_invalid_verification_code': 'Invalid verification code. Please try again.',
      'auth_verification_code_expired': 'Verification code has expired. Please request a new one.',
      'auth_email_not_verified': 'Email has not been verified. Please check your email.',
      'auth_account_locked': 'Account has been locked due to too many failed attempts.',
      'auth_session_expired': 'Your session has expired. Please log in again.',
      'auth_token_expired': 'Authentication token has expired. Please log in again.',
      'auth_invalid_credentials': 'Invalid credentials. Please check your login information.',
      'auth_account_not_verified': 'Account has not been verified. Please check your email.',
      
      'database_permission_denied': 'You don\'t have permission to perform this action.',
      'database_not_found': 'The requested data was not found.',
      'database_already_exists': 'This data already exists.',
      'database_unavailable': 'Database is temporarily unavailable. Please try again later.',
      'database_deadline_exceeded': 'Request took too long. Please try again.',
      'database_resource_exhausted': 'Service quota exceeded. Please try again later.',
      'database_cancelled': 'Request was cancelled.',
      'database_unknown_error': 'Unknown database error occurred.',
      'database_invalid_argument': 'Invalid argument provided.',
      'database_data_loss': 'Data loss occurred during operation.',
      'database_failed_precondition': 'Precondition failed. Please refresh and try again.',
      
      'storage_object_not_found': 'File not found.',
      'storage_unauthorized': 'You don\'t have permission to access this file.',
      'storage_retry_limit_exceeded': 'Too many requests. Please try again later.',
      'storage_quota_exceeded': 'Storage quota exceeded. Please free up space.',
      'storage_download_size_exceeded': 'File is too large to download.',
      'storage_upload_size_exceeded': 'File is too large to upload.',
      'storage_invalid_file_type': 'Invalid file type.',
      'storage_file_corrupted': 'File is corrupted and cannot be processed.',
      'storage_upload_failed': 'File upload failed. Please try again.',
      'storage_download_failed': 'File download failed. Please try again.',
      'storage_unknown_error': 'Unknown storage error occurred.',
      
      'location_service_disabled': 'Location services are disabled. Please enable location services in your device settings.',
      'location_permission_denied': 'Location permission denied. Please grant location permission to use this feature.',
      'location_permission_permanently_denied': 'Location permission permanently denied. Please enable in app settings.',
      'location_timeout': 'Location request timed out. Please try again.',
      'location_unavailable': 'Location services are currently unavailable. Please try again later.',
      'location_position_unavailable': 'Unable to determine current location. Please try again.',
      'location_settings_inadequate': 'Location settings are inadequate. Please check your device settings.',
      'location_unknown_error': 'Unknown location error occurred.',
      
      'maps_api_key_invalid': 'Maps API key is invalid. Please contact support.',
      'maps_api_quota_exceeded': 'Maps API quota exceeded. Please try again later.',
      'maps_over_query_limit': 'Too many requests to Maps API. Please try again later.',
      'maps_request_denied': 'Maps API request denied. Please check your permissions.',
      'maps_invalid_request': 'Invalid Maps API request. Please try again.',
      'maps_zero_results': 'No results found for this location.',
      'maps_unknown_location': 'Unknown location. Please try again.',
      'maps_route_not_found': 'Route not found. Please check your locations.',
      'maps_directions_failed': 'Failed to get directions. Please try again.',
      'maps_geocoding_failed': 'Failed to geocode location. Please try again.',
      'maps_unknown_error': 'Unknown maps error occurred.',
      
      'system_state_error': 'System state error. Please restart the app.',
      'system_assertion_failed': 'System assertion failed. Please restart the app.',
      'system_range_error': 'Invalid value provided. Please check your input.',
      'system_format_error': 'Invalid data format. Please check your input.',
      'system_type_error': 'Invalid data type. Please check your input.',
      'system_cast_error': 'Type conversion error. Please check your data.',
      'system_null_pointer_error': 'System error occurred. Please restart the app.',
      'system_stack_overflow': 'System stack overflow. Please restart the app.',
      'system_out_of_memory': 'System out of memory. Please restart the app.',
      'system_unknown_error': 'Unknown system error occurred. Please try again.',
      
      'validation_required_field': 'This field is required.',
      'validation_invalid_email': 'Please enter a valid email address.',
      'validation_invalid_phone': 'Please enter a valid phone number.',
      'validation_invalid_password': 'Password must be at least 8 characters long.',
      'validation_passwords_not_match': 'Passwords do not match.',
      'validation_invalid_name': 'Please enter a valid name.',
      'validation_min_length': 'Must be at least {minLength} characters.',
      'validation_max_length': 'Must be at most {maxLength} characters.',
      'validation_invalid_number': 'Please enter a valid number.',
      'validation_min_value': 'Must be at least {minValue}.',
      'validation_max_value': 'Must be at most {maxValue}.',
      'validation_invalid_date': 'Please enter a valid date.',
      'validation_invalid_time': 'Please enter a valid time.',
      'validation_invalid_url': 'Please enter a valid URL.',
      'validation_invalid_format': 'Invalid format. Please check your input.',
      'validation_contains_prohibited': 'Contains prohibited characters.',
      'validation_duplicate_value': 'This value already exists.',
      'validation_out_of_range': 'Value is out of valid range.',
    },
    'fr': {
      'network_connection_failed': 'La connexion réseau a échoué. Veuillez vérifier votre connexion Internet et réessayer.',
      'network_timeout': 'La demande a expiré. Veuillez réessayer.',
      'network_server_error': 'Erreur serveur. Veuillez réessayer plus tard.',
      'network_not_found': 'La ressource demandée n\'a pas été trouvée.',
      'network_unauthorized': 'Vous n\'êtes pas autorisé à accéder à cette ressource.',
      'network_forbidden': 'Vous n\'avez pas la permission d\'accéder à cette ressource.',
      'network_too_many_requests': 'Trop de demandes. Veuillez réessayer plus tard.',
      'network_internal_error': 'Erreur serveur interne. Veuillez réessayer plus tard.',
      'network_service_unavailable': 'Service temporairement indisponible. Veuillez réessayer plus tard.',
      'network_bad_gateway': 'Erreur de passerelle serveur. Veuillez réessayer plus tard.',
      'network_gateway_timeout': 'Délai d\'attente de la passerelle dépassé. Veuillez réessayer.',
      'network_unknown_error': 'Erreur réseau inconnue. Veuillez réessayer.',
      
      'auth_user_not_found': 'Utilisateur non trouvé. Veuillez vérifier vos identifiants.',
      'auth_wrong_password': 'Mot de passe incorrect. Veuillez réessayer.',
      'auth_invalid_email': 'Adresse e-mail invalide. Veuillez vérifier votre e-mail.',
      'auth_weak_password': 'Le mot de passe est trop faible. Veuillez choisir un mot de passe plus fort.',
      'auth_email_already_in_use': 'L\'e-mail est déjà utilisé. Veuillez utiliser un autre e-mail.',
      'auth_too_many_attempts': 'Trop de tentatives échouées. Veuillez réessayer plus tard.',
      'auth_user_disabled': 'Le compte a été désactivé. Veuillez contacter le support.',
      'auth_operation_not_allowed': 'Cette opération n\'est pas autorisée.',
      'auth_invalid_verification_code': 'Code de vérification invalide. Veuillez réessayer.',
      'auth_verification_code_expired': 'Le code de vérification a expiré. Veuillez en demander un nouveau.',
      'auth_email_not_verified': 'L\'e-mail n\'a pas été vérifié. Veuillez vérifier votre e-mail.',
      'auth_account_locked': 'Le compte a été bloqué en raison de trop de tentatives échouées.',
      'auth_session_expired': 'Votre session a expiré. Veuillez vous reconnecter.',
      'auth_token_expired': 'Le jeton d\'authentification a expiré. Veuillez vous reconnecter.',
      'auth_invalid_credentials': 'Identifiants invalides. Veuillez vérifier vos informations de connexion.',
      'auth_account_not_verified': 'Le compte n\'a pas été vérifié. Veuillez vérifier votre e-mail.',
      
      'validation_required_field': 'Ce champ est requis.',
      'validation_invalid_email': 'Veuillez entrer une adresse e-mail valide.',
      'validation_invalid_phone': 'Veuillez entrer un numéro de téléphone valide.',
      'validation_invalid_password': 'Le mot de passe doit contenir au moins 8 caractères.',
      'validation_passwords_not_match': 'Les mots de passe ne correspondent pas.',
      'validation_invalid_name': 'Veuillez entrer un nom valide.',
      'validation_min_length': 'Doit contenir au moins {minLength} caractères.',
      'validation_max_length': 'Doit contenir au plus {maxLength} caractères.',
      'validation_invalid_number': 'Veuillez entrer un nombre valide.',
      'validation_min_value': 'Doit être au moins {minValue}.',
      'validation_max_value': 'Doit être au plus {maxValue}.',
      'validation_invalid_date': 'Veuillez entrer une date valide.',
      'validation_invalid_time': 'Veuillez entrer une heure valide.',
      'validation_invalid_url': 'Veuillez entrer une URL valide.',
      'validation_invalid_format': 'Format invalide. Veuillez vérifier votre saisie.',
      'validation_contains_prohibited': 'Contient des caractères interdits.',
      'validation_duplicate_value': 'Cette valeur existe déjà.',
      'validation_out_of_range': 'La valeur est hors de la plage valide.',
    },
  };

  /// Validation messages by language
  static const Map<String, Map<String, String>> _validationMessages = {
    'en': {
      'ValidationType.required': 'This field is required.',
      'ValidationType.email': 'Please enter a valid email address.',
      'ValidationType.phone': 'Please enter a valid phone number.',
      'ValidationType.password': 'Password must be at least 8 characters long.',
      'ValidationType.name': 'Please enter a valid name.',
      'ValidationType.minLength': 'Must be at least {minLength} characters.',
      'ValidationType.maxLength': 'Must be at most {maxLength} characters.',
      'ValidationType.minValue': 'Must be at least {minValue}.',
      'ValidationType.maxValue': 'Must be at most {maxValue}.',
      'ValidationType.pattern': 'Invalid format. Please check your input.',
      'ValidationType.alpha': 'Only letters are allowed.',
      'ValidationType.alphaNumeric': 'Only letters and numbers are allowed.',
      'ValidationType.numeric': 'Please enter a valid number.',
      'ValidationType.date': 'Please enter a valid date.',
      'ValidationType.time': 'Please enter a valid time.',
      'ValidationType.url': 'Please enter a valid URL.',
      'ValidationType.custom': 'Invalid input. Please check your input.',
    },
    'fr': {
      'ValidationType.required': 'Ce champ est requis.',
      'ValidationType.email': 'Veuillez entrer une adresse e-mail valide.',
      'ValidationType.phone': 'Veuillez entrer un numéro de téléphone valide.',
      'ValidationType.password': 'Le mot de passe doit contenir au moins 8 caractères.',
      'ValidationType.name': 'Veuillez entrer un nom valide.',
      'ValidationType.minLength': 'Doit contenir au moins {minLength} caractères.',
      'ValidationType.maxLength': 'Doit contenir au plus {maxLength} caractères.',
      'ValidationType.minValue': 'Doit être au moins {minValue}.',
      'ValidationType.maxValue': 'Doit être au plus {maxValue}.',
      'ValidationType.pattern': 'Format invalide. Veuillez vérifier votre saisie.',
      'ValidationType.alpha': 'Seules les lettres sont autorisées.',
      'ValidationType.alphaNumeric': 'Seules les lettres et les chiffres sont autorisés.',
      'ValidationType.numeric': 'Veuillez entrer un nombre valide.',
      'ValidationType.date': 'Veuillez entrer une date valide.',
      'ValidationType.time': 'Veuillez entrer une heure valide.',
      'ValidationType.url': 'Veuillez entrer une URL valide.',
      'ValidationType.custom': 'Saisie invalide. Veuillez vérifier votre saisie.',
    },
  };

  /// Network error messages by language
  static const Map<String, Map<String, String>> _networkMessages = {
    'en': {
      'NetworkErrorType.connectionFailed': 'Network connection failed. Please check your internet connection and try again.',
      'NetworkErrorType.timeout': 'Request timed out. Please try again.',
      'NetworkErrorType.serverError': 'Server error occurred. Please try again later.',
      'NetworkErrorType.notFound': 'The requested resource was not found.',
      'NetworkErrorType.unauthorized': 'You are not authorized to access this resource.',
      'NetworkErrorType.forbidden': 'You do not have permission to access this resource.',
      'NetworkErrorType.tooManyRequests': 'Too many requests. Please try again later.',
      'NetworkErrorType.serviceUnavailable': 'Service is temporarily unavailable. Please try again later.',
      'NetworkErrorType.unknown': 'Unknown network error occurred. Please try again.',
    },
    'fr': {
      'NetworkErrorType.connectionFailed': 'La connexion réseau a échoué. Veuillez vérifier votre connexion Internet et réessayer.',
      'NetworkErrorType.timeout': 'La demande a expiré. Veuillez réessayer.',
      'NetworkErrorType.serverError': 'Erreur serveur. Veuillez réessayer plus tard.',
      'NetworkErrorType.notFound': 'La ressource demandée n\'a pas été trouvée.',
      'NetworkErrorType.unauthorized': 'Vous n\'êtes pas autorisé à accéder à cette ressource.',
      'NetworkErrorType.forbidden': 'Vous n\'avez pas la permission d\'accéder à cette ressource.',
      'NetworkErrorType.tooManyRequests': 'Trop de demandes. Veuillez réessayer plus tard.',
      'NetworkErrorType.serviceUnavailable': 'Service temporairement indisponible. Veuillez réessayer plus tard.',
      'NetworkErrorType.unknown': 'Erreur réseau inconnue. Veuillez réessayer.',
    },
  };

  /// Authentication error messages by language
  static const Map<String, Map<String, String>> _authMessages = {
    'en': {
      'AuthErrorType.userNotFound': 'User not found. Please check your credentials.',
      'AuthErrorType.wrongPassword': 'Incorrect password. Please try again.',
      'AuthErrorType.invalidEmail': 'Invalid email address. Please check your email.',
      'AuthErrorType.weakPassword': 'Password is too weak. Please choose a stronger password.',
      'AuthErrorType.emailAlreadyInUse': 'Email is already in use. Please use a different email.',
      'AuthErrorType.tooManyAttempts': 'Too many failed attempts. Please try again later.',
      'AuthErrorType.userDisabled': 'Account has been disabled. Please contact support.',
      'AuthErrorType.operationNotAllowed': 'This operation is not allowed.',
      'AuthErrorType.invalidVerificationCode': 'Invalid verification code. Please try again.',
      'AuthErrorType.verificationCodeExpired': 'Verification code has expired. Please request a new one.',
      'AuthErrorType.emailNotVerified': 'Email has not been verified. Please check your email.',
      'AuthErrorType.accountLocked': 'Account has been locked due to too many failed attempts.',
      'AuthErrorType.sessionExpired': 'Your session has expired. Please log in again.',
      'AuthErrorType.tokenExpired': 'Authentication token has expired. Please log in again.',
      'AuthErrorType.invalidCredentials': 'Invalid credentials. Please check your login information.',
      'AuthErrorType.accountNotVerified': 'Account has not been verified. Please check your email.',
    },
    'fr': {
      'AuthErrorType.userNotFound': 'Utilisateur non trouvé. Veuillez vérifier vos identifiants.',
      'AuthErrorType.wrongPassword': 'Mot de passe incorrect. Veuillez réessayer.',
      'AuthErrorType.invalidEmail': 'Adresse e-mail invalide. Veuillez vérifier votre e-mail.',
      'AuthErrorType.weakPassword': 'Le mot de passe est trop faible. Veuillez choisir un mot de passe plus fort.',
      'AuthErrorType.emailAlreadyInUse': 'L\'e-mail est déjà utilisé. Veuillez utiliser un autre e-mail.',
      'AuthErrorType.tooManyAttempts': 'Trop de tentatives échouées. Veuillez réessayer plus tard.',
      'AuthErrorType.userDisabled': 'Le compte a été désactivé. Veuillez contacter le support.',
      'AuthErrorType.operationNotAllowed': 'Cette opération n\'est pas autorisée.',
      'AuthErrorType.invalidVerificationCode': 'Code de vérification invalide. Veuillez réessayer.',
      'AuthErrorType.verificationCodeExpired': 'Le code de vérification a expiré. Veuillez en demander un nouveau.',
      'AuthErrorType.emailNotVerified': 'L\'e-mail n\'a pas été vérifié. Veuillez vérifier votre e-mail.',
      'AuthErrorType.accountLocked': 'Le compte a été bloqué en raison de trop de tentatives échouées.',
      'AuthErrorType.sessionExpired': 'Votre session a expiré. Veuillez vous reconnecter.',
      'AuthErrorType.tokenExpired': 'Le jeton d\'authentification a expiré. Veuillez vous reconnecter.',
      'AuthErrorType.invalidCredentials': 'Identifiants invalides. Veuillez vérifier vos informations de connexion.',
      'AuthErrorType.accountNotVerified': 'Le compte n\'a pas été vérifié. Veuillez vérifier votre e-mail.',
    },
  };

  /// Database error messages by language
  static const Map<String, Map<String, String>> _databaseMessages = {
    'en': {
      'DatabaseErrorType.permissionDenied': 'You don\'t have permission to perform this action.',
      'DatabaseErrorType.notFound': 'The requested data was not found.',
      'DatabaseErrorType.alreadyExists': 'This data already exists.',
      'DatabaseErrorType.unavailable': 'Database is temporarily unavailable. Please try again later.',
      'DatabaseErrorType.deadlineExceeded': 'Request took too long. Please try again.',
      'DatabaseErrorType.resourceExhausted': 'Service quota exceeded. Please try again later.',
      'DatabaseErrorType.cancelled': 'Request was cancelled.',
      'DatabaseErrorType.unknown': 'Unknown database error occurred. Please try again.',
    },
    'fr': {
      'DatabaseErrorType.permissionDenied': 'Vous n\'avez pas la permission d\'effectuer cette action.',
      'DatabaseErrorType.notFound': 'Les données demandées n\'ont pas été trouvées.',
      'DatabaseErrorType.alreadyExists': 'Ces données existent déjà.',
      'DatabaseErrorType.unavailable': 'La base de données est temporairement indisponible. Veuillez réessayer plus tard.',
      'DatabaseErrorType.deadlineExceeded': 'La demande a pris trop de temps. Veuillez réessayer.',
      'DatabaseErrorType.resourceExhausted': 'Quota de service dépassé. Veuillez réessayer plus tard.',
      'DatabaseErrorType.cancelled': 'La demande a été annulée.',
      'DatabaseErrorType.unknown': 'Erreur de base de données inconnue. Veuillez réessayer.',
    },
  };

  /// Storage error messages by language
  static const Map<String, Map<String, String>> _storageMessages = {
    'en': {
      'StorageErrorType.objectNotFound': 'File not found.',
      'StorageErrorType.unauthorized': 'You don\'t have permission to access this file.',
      'StorageErrorType.retryLimitExceeded': 'Too many requests. Please try again later.',
      'StorageErrorType.quotaExceeded': 'Storage quota exceeded. Please free up space.',
      'StorageErrorType.downloadSizeExceeded': 'File is too large to download.',
      'StorageErrorType.uploadSizeExceeded': 'File is too large to upload.',
      'StorageErrorType.invalidFileType': 'Invalid file type.',
      'StorageErrorType.fileCorrupted': 'File is corrupted and cannot be processed.',
      'StorageErrorType.uploadFailed': 'File upload failed. Please try again.',
      'StorageErrorType.downloadFailed': 'File download failed. Please try again.',
      'StorageErrorType.unknown': 'Unknown storage error occurred. Please try again.',
    },
    'fr': {
      'StorageErrorType.objectNotFound': 'Fichier non trouvé.',
      'StorageErrorType.unauthorized': 'Vous n\'avez pas la permission d\'accéder à ce fichier.',
      'StorageErrorType.retryLimitExceeded': 'Trop de demandes. Veuillez réessayer plus tard.',
      'StorageErrorType.quotaExceeded': 'Quota de stockage dépassé. Veuillez libérer de l\'espace.',
      'StorageErrorType.downloadSizeExceeded': 'Le fichier est trop volumineux à télécharger.',
      'StorageErrorType.uploadSizeExceeded': 'Le fichier est trop volumineux à télécharger.',
      'StorageErrorType.invalidFileType': 'Type de fichier invalide.',
      'StorageErrorType.fileCorrupted': 'Le fichier est corrompu et ne peut être traité.',
      'StorageErrorType.uploadFailed': 'Le téléchargement du fichier a échoué. Veuillez réessayer.',
      'StorageErrorType.downloadFailed': 'Le téléchargement du fichier a échoué. Veuillez réessayer.',
      'StorageErrorType.unknown': 'Erreur de stockage inconnue. Veuillez réessayer.',
    },
  };

  /// Location error messages by language
  static const Map<String, Map<String, String>> _locationMessages = {
    'en': {
      'LocationErrorType.serviceDisabled': 'Location services are disabled. Please enable location services in your device settings.',
      'LocationErrorType.permissionDenied': 'Location permission denied. Please grant location permission to use this feature.',
      'LocationErrorType.permissionPermanentlyDenied': 'Location permission permanently denied. Please enable in app settings.',
      'LocationErrorType.timeout': 'Location request timed out. Please try again.',
      'LocationErrorType.unavailable': 'Location services are currently unavailable. Please try again later.',
      'LocationErrorType.positionUnavailable': 'Unable to determine current location. Please try again.',
      'LocationErrorType.settingsInadequate': 'Location settings are inadequate. Please check your device settings.',
      'LocationErrorType.unknown': 'Unknown location error occurred. Please try again.',
    },
    'fr': {
      'LocationErrorType.serviceDisabled': 'Les services de localisation sont désactivés. Veuillez activer les services de localisation dans les paramètres de votre appareil.',
      'LocationErrorType.permissionDenied': 'Autorisation de localisation refusée. Veuillez accorder l\'autorisation de localisation pour utiliser cette fonctionnalité.',
      'LocationErrorType.permissionPermanentlyDenied': 'Autorisation de localisation refusée de manière permanente. Veuillez activer dans les paramètres de l\'application.',
      'LocationErrorType.timeout': 'La demande de localisation a expiré. Veuillez réessayer.',
      'LocationErrorType.unavailable': 'Les services de localisation sont actuellement indisponibles. Veuillez réessayer plus tard.',
      'LocationErrorType.positionUnavailable': 'Impossible de déterminer la position actuelle. Veuillez réessayer.',
      'LocationErrorType.settingsInadequate': 'Les paramètres de localisation sont inadéquats. Veuillez vérifier les paramètres de votre appareil.',
      'LocationErrorType.unknown': 'Erreur de localisation inconnue. Veuillez réessayer.',
    },
  };

  /// Maps error messages by language
  static const Map<String, Map<String, String>> _mapsMessages = {
    'en': {
      'MapsErrorType.apiKeyInvalid': 'Maps API key is invalid. Please contact support.',
      'MapsErrorType.apiQuotaExceeded': 'Maps API quota exceeded. Please try again later.',
      'MapsErrorType.overQueryLimit': 'Too many requests to Maps API. Please try again later.',
      'MapsErrorType.requestDenied': 'Maps API request denied. Please check your permissions.',
      'MapsErrorType.invalidRequest': 'Invalid Maps API request. Please try again.',
      'MapsErrorType.zeroResults': 'No results found for this location.',
      'MapsErrorType.unknownLocation': 'Unknown location. Please try again.',
      'MapsErrorType.routeNotFound': 'Route not found. Please check your locations.',
      'MapsErrorType.directionsFailed': 'Failed to get directions. Please try again.',
      'MapsErrorType.geocodingFailed': 'Failed to geocode location. Please try again.',
      'MapsErrorType.unknown': 'Unknown maps error occurred. Please try again.',
    },
    'fr': {
      'MapsErrorType.apiKeyInvalid': 'La clé API Maps est invalide. Veuillez contacter le support.',
      'MapsErrorType.apiQuotaExceeded': 'Quota API Maps dépassé. Veuillez réessayer plus tard.',
      'MapsErrorType.overQueryLimit': 'Trop de demandes à l\'API Maps. Veuillez réessayer plus tard.',
      'MapsErrorType.requestDenied': 'Demande API Maps refusée. Veuillez vérifier vos autorisations.',
      'MapsErrorType.invalidRequest': 'Demande API Maps invalide. Veuillez réessayer.',
      'MapsErrorType.zeroResults': 'Aucun résultat trouvé pour cet emplacement.',
      'MapsErrorType.unknownLocation': 'Emplacement inconnu. Veuillez réessayer.',
      'MapsErrorType.routeNotFound': 'Itinéraire non trouvé. Veuillez vérifier vos emplacements.',
      'MapsErrorType.directionsFailed': 'Échec de l\'obtention des directions. Veuillez réessayer.',
      'MapsErrorType.geocodingFailed': 'Échec du géocodage de l\'emplacement. Veuillez réessayer.',
      'MapsErrorType.unknown': 'Erreur Maps inconnue. Veuillez réessayer.',
    },
  };

  /// System error messages by language
  static const Map<String, Map<String, String>> _systemMessages = {
    'en': {
      'SystemErrorType.stateError': 'System state error. Please restart the app.',
      'SystemErrorType.assertionFailed': 'System assertion failed. Please restart the app.',
      'SystemErrorType.rangeError': 'Invalid value provided. Please check your input.',
      'SystemErrorType.formatError': 'Invalid data format. Please check your input.',
      'SystemErrorType.typeError': 'Invalid data type. Please check your input.',
      'SystemErrorType.castError': 'Type conversion error. Please check your data.',
      'SystemErrorType.nullPointerError': 'System error occurred. Please restart the app.',
      'SystemErrorType.stackOverflow': 'System stack overflow. Please restart the app.',
      'SystemErrorType.outOfMemory': 'System out of memory. Please restart the app.',
      'SystemErrorType.unknown': 'Unknown system error occurred. Please try again.',
    },
    'fr': {
      'SystemErrorType.stateError': 'Erreur d\'état système. Veuillez redémarrer l\'application.',
      'SystemErrorType.assertionFailed': 'Échec d\'assertion système. Veuillez redémarrer l\'application.',
      'SystemErrorType.rangeError': 'Valeur invalide fournie. Veuillez vérifier votre saisie.',
      'SystemErrorType.formatError': 'Format de données invalide. Veuillez vérifier votre saisie.',
      'SystemErrorType.typeError': 'Type de données invalide. Veuillez vérifier votre saisie.',
      'SystemErrorType.castError': 'Erreur de conversion de type. Veuillez vérifier vos données.',
      'SystemErrorType.nullPointerError': 'Erreur système. Veuillez redémarrer l\'application.',
      'SystemErrorType.stackOverflow': 'Dépassement de pile système. Veuillez redémarrer l\'application.',
      'SystemErrorType.outOfMemory': 'Mémoire système insuffisante. Veuillez redémarrer l\'application.',
      'SystemErrorType.unknown': 'Erreur système inconnue. Veuillez réessayer.',
    },
  };
}

/// Validation error types
enum ValidationType {
  required,
  email,
  phone,
  password,
  name,
  minLength,
  maxLength,
  minValue,
  maxValue,
  pattern,
  alpha,
  alphaNumeric,
  numeric,
  date,
  time,
  url,
  custom,
}

/// Network error types
enum NetworkErrorType {
  connectionFailed,
  timeout,
  serverError,
  notFound,
  unauthorized,
  forbidden,
  tooManyRequests,
  serviceUnavailable,
  unknown,
}

/// Authentication error types
enum AuthErrorType {
  userNotFound,
  wrongPassword,
  invalidEmail,
  weakPassword,
  emailAlreadyInUse,
  tooManyAttempts,
  userDisabled,
  operationNotAllowed,
  invalidVerificationCode,
  verificationCodeExpired,
  emailNotVerified,
  accountLocked,
  sessionExpired,
  tokenExpired,
  invalidCredentials,
  accountNotVerified,
}

/// Database error types
enum DatabaseErrorType {
  permissionDenied,
  notFound,
  alreadyExists,
  unavailable,
  deadlineExceeded,
  resourceExhausted,
  cancelled,
  unknown,
}

/// Storage error types
enum StorageErrorType {
  objectNotFound,
  unauthorized,
  retryLimitExceeded,
  quotaExceeded,
  downloadSizeExceeded,
  uploadSizeExceeded,
  invalidFileType,
  fileCorrupted,
  uploadFailed,
  downloadFailed,
  unknown,
}

/// Location error types
enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  timeout,
  unavailable,
  positionUnavailable,
  settingsInadequate,
  unknown,
}

/// Maps error types
enum MapsErrorType {
  apiKeyInvalid,
  apiQuotaExceeded,
  overQueryLimit,
  requestDenied,
  invalidRequest,
  zeroResults,
  unknownLocation,
  routeNotFound,
  directionsFailed,
  geocodingFailed,
  unknown,
}

/// System error types
enum SystemErrorType {
  stateError,
  assertionFailed,
  rangeError,
  formatError,
  typeError,
  castError,
  nullPointerError,
  stackOverflow,
  outOfMemory,
  unknown,
}
