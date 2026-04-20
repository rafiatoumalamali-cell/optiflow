import 'package:flutter/material.dart';
import '../../utils/logger.dart';
import 'error_widget.dart';

typedef ErrorFallbackBuilder = Widget Function(BuildContext context, Object error, StackTrace? stackTrace);

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final ErrorFallbackBuilder? fallbackBuilder;
  final void Function(Object error, StackTrace? stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallbackBuilder?.call(context, _error!, _stackTrace) ??
          ErrorContainer(
            title: 'Something went wrong',
            message: 'An unexpected error occurred. Please try again.',
            onRetry: _reset,
          );
    }

    try {
      return widget.child;
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      return widget.fallbackBuilder?.call(context, error, stackTrace) ??
          ErrorContainer(
            title: 'Something went wrong',
            message: 'An unexpected error occurred. Please try again.',
            onRetry: _reset,
          );
    }
  }

  void _reportError(Object error, StackTrace stackTrace) {
    Logger.error('ErrorBoundary caught an error', error: error, stackTrace: stackTrace);
    widget.onError?.call(error, stackTrace);
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });
  }

  void _reset() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }
}
