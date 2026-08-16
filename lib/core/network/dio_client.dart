import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

// NOTE: the legacy singleton DioClient (instance getter + AuthInterceptor +
// AppException mapping) was removed; the active implementation below uses
// static methods with per-request Firebase-token options.

/// Small shim so we can use debugPrint in core layer without importing Flutter
void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}



class DioClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://everywhere-data-app.onrender.com",
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  /// 🔑 Get Firebase token
  static Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final token = await user.getIdToken();
    return token;
  }

  /// 🧱 Build headers
  static Future<Options> _options() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("User not authenticated");
    }

    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  /// 📥 GET
  static Future<dynamic> get(
      String path, {
        Map<String, dynamic>? queryParameters,
      }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: await _options(),
      );

      print(response.data);

      return response.data;

    } on DioException catch (e) {
      print(e);
      throw _mapError(e);
    }
  }

  /// 📤 POST
  static Future<dynamic> post(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
      }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: await _options(),
      );

      print(response.data);

      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// 📤 POST multipart (file upload). Pass a Dio [FormData]; the auth header is
  /// injected but Content-Type is left to Dio so the multipart boundary is set.
  static Future<dynamic> postMultipart(
    String path,
    FormData formData,
  ) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        options: await _options(),
      );
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// 🩹 PATCH
  static Future<dynamic> patch(
      String path, {
        dynamic data,
      }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        options: await _options(),
      );

      print(response.data);
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// 🗑️ DELETE
  static Future<dynamic> delete(
      String path, {
        dynamic data,
      }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        options: await _options(),
      );
      print(response.data);
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// ❌ Error handler (clean)
  static Exception _mapError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data is Map
          ? e.response?.data['message'] ?? 'Server error'
          : 'Server error';

      print("❌ API ERROR [$statusCode]: $message");

      return Exception(message);
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Request timed out');
    }

    if (e.type == DioExceptionType.connectionError) {
      return Exception('No internet connection');
    }

    return Exception(e.message ?? 'Unexpected error');
  }
}