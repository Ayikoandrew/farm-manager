class ErrorSanitizer {
  static final RegExp _urlPattern = RegExp(
    r'https?:\/\/[^\s<>"{}|\\^`\[\]]+',
    caseSensitive: false,
  );

  static final RegExp _ipPattern = RegExp(
    r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(:\d+)?\b',
  );

  static final RegExp _uuidPattern = RegExp(
    r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
    caseSensitive: false,
  );

  static String sanitize(dynamic error) {
    String message = error.toString();

    if (_isConnectionError(message)) {
      return 'Unable to connect. Please check your internet connection.';
    }

    if (_isAuthError(message)) {
      return 'Authentication error. Please try logging in again.';
    }

    if (_isServerError(message)) {
      return 'Server error. Please try again later.';
    }

    message = message.replaceAll(_urlPattern, '[server]');

    message = message.replaceAll(_ipPattern, '[address]');

    message = message.replaceAll(_uuidPattern, '[id]');

    message = _removeSensitiveKeywords(message);

    return message;
  }

  static bool _isConnectionError(String message) {
    final connectionKeywords = [
      'SocketException',
      'Connection refused',
      'Connection timed out',
      'Failed host lookup',
      'Network is unreachable',
      'No route to host',
      'Connection reset',
      'HandshakeException',
      'CERTIFICATE_VERIFY_FAILED',
    ];

    return connectionKeywords.any(
      (keyword) => message.toLowerCase().contains(keyword.toLowerCase()),
    );
  }

  static bool _isAuthError(String message) {
    final authKeywords = [
      'unauthorized',
      '401',
      'invalid token',
      'token expired',
      'jwt',
      'authentication',
    ];

    return authKeywords.any(
      (keyword) => message.toLowerCase().contains(keyword.toLowerCase()),
    );
  }

  static bool _isServerError(String message) {
    final serverKeywords = [
      '500',
      '502',
      '503',
      '504',
      'internal server error',
      'bad gateway',
      'service unavailable',
    ];

    return serverKeywords.any(
      (keyword) => message.toLowerCase().contains(keyword.toLowerCase()),
    );
  }

  static String _removeSensitiveKeywords(String message) {
    final sensitivePatterns = [
      RegExp(r'api[_-]?key[=:]\s*\S+', caseSensitive: false),
      RegExp(r'password[=:]\s*\S+', caseSensitive: false),
      RegExp(r'token[=:]\s*\S+', caseSensitive: false),
      RegExp(r'secret[=:]\s*\S+', caseSensitive: false),
      RegExp(r'Bearer\s+\S+', caseSensitive: false),
    ];

    for (final pattern in sensitivePatterns) {
      message = message.replaceAll(pattern, '[redacted]');
    }

    return message;
  }

  static String getUserFriendlyMessage(dynamic error) {
    final message = error.toString().toLowerCase();

    if (_isConnectionError(message)) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (_isAuthError(message)) {
      return 'Your session has expired. Please log in again.';
    }

    if (_isServerError(message)) {
      return 'Something went wrong on our end. Please try again later.';
    }

    if (message.contains('timeout')) {
      return 'The request timed out. Please try again.';
    }

    if (message.contains('permission') || message.contains('forbidden')) {
      return 'You don\'t have permission to perform this action.';
    }

    if (message.contains('not found') || message.contains('404')) {
      return 'The requested resource was not found.';
    }

    return sanitize(error);
  }
}
