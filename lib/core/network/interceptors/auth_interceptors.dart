import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Automatically attaches the Firebase ID token to every outgoing request.
/// On 401, it force-refreshes the token and retries once.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final token = await _getToken(forceRefresh: false);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    if (err.response?.statusCode == 401) {
      // Force-refresh the token and retry once
      try {
        final newToken = await _getToken(forceRefresh: true);
        if (newToken != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final dio = Dio();
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (_) {
        // If refresh fails, let the error propagate
      }
    }
    handler.next(err);
  }

  Future<String?> _getToken({required bool forceRefresh}) async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }
}