import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';
import '../utils/app_colors.dart';

class ErrorHandlingService {
  static void showUserFriendlyError(BuildContext context, String error, {String? action}) {
    final userMessage = _getUserFriendlyMessage(error, action: action);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Something went wrong',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Action: $action',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    userMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.errorRed,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showNetworkError(BuildContext context, {String? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Internet Connection',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Please check your internet connection and try again.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'We couldn\'t: $action',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            // Retry action can be customized based on context
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showApiError(BuildContext context, String endpoint, {String? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Server Connection Failed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unable to connect to our servers. Please try again.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Failed action: $action',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.errorRed,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showLoadingMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 10),
      ),
    );
  }

  static String _getUserFriendlyMessage(String technicalError, {String? action}) {
    // Map common technical errors to user-friendly messages
    final errorMap = {
      'Connection refused': 'Our servers are temporarily unavailable. Please try again in a few minutes.',
      'Connection timeout': 'The request took too long. Please check your connection and try again.',
      'Connection reset': 'Your internet connection was interrupted. Please check your network.',
      'Host not found': 'Unable to reach our servers. Please check your internet connection.',
      'SSL handshake failed': 'Secure connection failed. Please try again.',
      'Socket exception': 'Network connection error. Please check your internet.',
      'HTTP 400': 'Invalid request. Please try again.',
      'HTTP 401': 'You need to log in again to continue.',
      'HTTP 403': 'You don\'t have permission for this action.',
      'HTTP 404': 'The requested information was not found.',
      'HTTP 500': 'Our servers encountered an error. Please try again.',
      'HTTP 502': 'Our servers are temporarily unavailable. Please try again.',
      'HTTP 503': 'Our servers are temporarily busy. Please try again.',
      'HTTP 504': 'The request took too long. Please try again.',
      'Network is unreachable': 'No internet connection. Please check your network settings.',
      'No address associated with hostname': 'Unable to connect to servers. Please check your internet.',
    };

    // Check for exact matches first
    for (final entry in errorMap.entries) {
      if (technicalError.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Check for partial matches
    if (technicalError.toLowerCase().contains('timeout')) {
      return 'The request took too long. Please try again.';
    }
    if (technicalError.toLowerCase().contains('connection')) {
      return 'Network connection problem. Please check your internet and try again.';
    }
    if (technicalError.toLowerCase().contains('auth')) {
      return 'Authentication problem. Please log in again and try.';
    }
    if (technicalError.toLowerCase().contains('permission')) {
      return 'You don\'t have permission for this action.';
    }

    // Default message
    return 'Something unexpected happened. Please try again or contact support if the problem continues.';
  }

  static Future<bool> checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      Logger.error('Error checking connectivity', name: 'ErrorHandling', error: e);
      return false; // Assume no connectivity if check fails
    }
  }

  static Future<void> handleNetworkError(
    BuildContext context, 
    dynamic error, 
    StackTrace? stackTrace, {
    String? action,
    VoidCallback? onRetry,
  }) async {
    Logger.error('Network error occurred', name: 'ErrorHandling', error: error, stackTrace: stackTrace);
    
    final hasConnectivity = await checkConnectivity();
    
    if (hasConnectivity) {
      // Has internet but API/server error
      showApiError(context, 'unknown', action: action);
    } else {
      // No internet connection
      showNetworkError(context, action: action);
    }

    // Store error for retry logic
    if (onRetry != null) {
      // Could store in a retry queue or show retry button
    }
  }

  static Future<void> handleApiError(
    BuildContext context,
    dynamic error,
    StackTrace? stackTrace, {
    String? endpoint,
    String? action,
    VoidCallback? onRetry,
  }) async {
    Logger.error('API error occurred', name: 'ErrorHandling', error: error, stackTrace: stackTrace);
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('connection') || errorString.contains('network')) {
      await handleNetworkError(context, error, stackTrace, action: action);
    } else if (errorString.contains('401')) {
      _showAuthError(context, action: action);
    } else if (errorString.contains('403')) {
      _showPermissionError(context, action: action);
    } else if (errorString.contains('404')) {
      _showNotFoundError(context, action: action);
    } else if (errorString.contains('500') || errorString.contains('502') || errorString.contains('503')) {
      _showServerError(context, action: action);
    } else {
      showUserFriendlyError(context, error.toString(), action: action);
    }
  }

  static void _showAuthError(BuildContext context, {String? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Authentication Required',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Please log in again to continue.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Login',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to login
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ),
    );
  }

  static void _showPermissionError(BuildContext context, {String? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.block, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Permission Denied',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'You don\'t have permission for this action.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void _showNotFoundError(BuildContext context, {String? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.search_off, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Not Found',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'The requested information was not found.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void _showServerError(BuildContext context, {String? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Server Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Our servers are having issues. Please try again.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.errorRed,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
