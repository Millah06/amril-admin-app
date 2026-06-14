/// Represents a structured API/network error throughout the app.
/// Instead of catching raw DioException everywhere, we map to this.
class AppException implements Exception {
  const AppException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isServerError => (statusCode ?? 0) >= 500;

  @override
  String toString() => 'AppException($statusCode): $message';
}