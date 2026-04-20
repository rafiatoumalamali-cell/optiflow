import 'package:flutter/material.dart';
import 'app_localizations.dart';

class ErrorUtils {
  static String localizeError(Object error, BuildContext context, {bool includePrefix = true}) {
    final loc = AppLocalizations.of(context);
    var message = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

    final translated = loc?.translate(message);
    if (translated != null && translated != message) {
      message = translated;
    }

    if (!includePrefix) {
      return message;
    }

    final errorPrefix = loc?.translate('error_prefix') ?? 'Error';
    return '$errorPrefix: $message';
  }
}
