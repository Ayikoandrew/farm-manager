import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';
import '../services/connectivity_service.dart';
import '../utils/error_sanitizer.dart';

export '../services/connectivity_service.dart';
export '../utils/error_sanitizer.dart';

class ConnectivityWrapper extends ConsumerWidget {
  final Widget child;
  final Widget? offlineWidget;
  final bool showOfflineSnackbar;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.offlineWidget,
    this.showOfflineSnackbar = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStreamProvider);

    return connectivityAsync.when(
      data: (isConnected) {
        if (!isConnected) {
          return offlineWidget ?? const NoInternetScreen();
        }
        return child;
      },
      loading: () => child,
      error: (_, _) => child,
    );
  }
}

class NoInternetScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? title;
  final String? message;

  const NoInternetScreen({super.key, this.onRetry, this.title, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 64,
                      color: colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  title ?? 'No Internet Connection',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message ??
                      'Please check your internet connection and try again.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (onRetry != null)
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NoInternetBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetBanner({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No internet connection',
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
        ],
      ),
    );
  }
}

mixin ConnectivityMixin<T extends StatefulWidget> on State<T> {
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final connected = await ConnectivityService().checkConnection();
    if (mounted) {
      setState(() => _isConnected = connected);
    }
  }

  Future<void> retryConnection() async {
    await _checkConnectivity();
  }
}

class ErrorDisplay extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final bool sanitize;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.onRetry,
    this.sanitize = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final message = sanitize
        ? ErrorSanitizer.getUserFriendlyMessage(error)
        : error.toString();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
          ],
        ),
      ),
    );
  }
}

class SafeAsyncBuilder<T> extends ConsumerWidget {
  final AsyncValue<T> asyncValue;
  final Widget Function(T data) builder;
  final Widget Function()? loadingBuilder;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final VoidCallback? onRetry;

  const SafeAsyncBuilder({
    super.key,
    required this.asyncValue,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStreamProvider);
    final isConnected = connectivityAsync.when(
      data: (connected) => connected,
      loading: () => true,
      error: (_, _) => true,
    );

    return asyncValue.when(
      data: builder,
      loading: () =>
          loadingBuilder?.call() ??
          const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        final errorMessage = ErrorSanitizer.getUserFriendlyMessage(error);
        if (!isConnected ||
            errorMessage.contains('internet') ||
            errorMessage.contains('connect')) {
          return NoInternetScreen(onRetry: onRetry);
        }

        if (errorBuilder != null) {
          return errorBuilder!(error, stack);
        }

        return ErrorDisplay(error: error, onRetry: onRetry);
      },
    );
  }
}
