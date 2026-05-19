/// Base class for all app-level exceptions.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown by [ErrorInterceptor] when the server returns a non-2xx status.
class NetworkException extends AppException {
  const NetworkException({required this.statusCode, required String message})
      : super(message);

  final int statusCode;

  bool get isNotFound => statusCode == 404;
  bool get isUnauthorized => statusCode == 401;
  bool get isServerError => statusCode >= 500;
}

/// Thrown when the device has no internet connectivity.
class NoConnectionException extends AppException {
  const NoConnectionException()
      : super('No internet connection. Check your network and try again.');
}

/// Thrown when JSON parsing fails.
class ParseException extends AppException {
  const ParseException(String details) : super('Failed to parse response: $details');
}

/// Thrown for Firestore / Firebase errors.
class DatabaseException extends AppException {
  const DatabaseException(String details) : super('Database error: $details');
}
