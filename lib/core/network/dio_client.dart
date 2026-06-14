import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/api_constants.dart';
import '../erorrs/app_exception.dart';
import 'interceptors/auth_interceptors.dart';

/// Singleton Dio instance pre-configured with:
///   - Base URL & headers
///   - Auth token injection (AuthInterceptor)
///   - Unified error mapping to [AppException]
///
/// Usage:
///   final dio = DioClient.instance;
///   final resp = await dio.get('/admin/stats');
// class DioClient {
//   DioClient._();
//
//   static Dio? _instance;
//
//   static Dio get instance {
//     _instance ??= _build();
//     return _instance!;
//   }
//
//   Future<String?> getIdToken() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       return await user.getIdToken();
//     }
//     return null;
//   }
//
//   static Dio _build() {
//
//     final dio = Dio(
//       BaseOptions(
//         baseUrl: ApiConstants.baseUrl,
//         connectTimeout: const Duration(seconds: 15),
//         receiveTimeout: const Duration(seconds: 30),
//         headers: {
//
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       ),
//     );
//
//     // Attach Firebase token to every request
//     dio.interceptors.add(AuthInterceptor(FirebaseAuth.instance));
//
//     // Log requests in debug mode
//     dio.interceptors.add(
//       LogInterceptor(
//         requestBody: true,
//         responseBody: true,
//         error: true,
//         logPrint: (o) => debugPrint('[DIO] $o'),
//       ),
//     );
//
//     return dio;
//   }
//
//   /// Makes a [GET] request and returns the decoded response data.
//   /// Throws [AppException] on any error.
//   static Future<dynamic> get(
//       String path, {
//         Map<String, dynamic>? queryParameters,
//       }) async {
//     try {
//       final response = await instance.get(
//         path,
//         queryParameters: queryParameters,
//       );
//       return response.data;
//     } on DioException catch (e) {
//       throw _mapError(e);
//     }
//   }
//
//   /// Makes a [POST] request.
//   static Future<dynamic> post(
//       String path, {
//         dynamic data,
//         Map<String, dynamic>? queryParameters,
//       }) async {
//     try {
//       final response = await instance.post(
//         path,
//         data: data,
//         queryParameters: queryParameters,
//       );
//       return response.data;
//     } on DioException catch (e) {
//       throw _mapError(e);
//     }
//   }
//
//   /// Makes a [PATCH] request.
//   static Future<dynamic> patch(
//       String path, {
//         dynamic data,
//       }) async {
//     try {
//       final response = await instance.patch(path, data: data);
//       return response.data;
//     } on DioException catch (e) {
//       throw _mapError(e);
//     }
//   }
//
//   /// Maps raw [DioException] → structured [AppException].
//   static AppException _mapError(DioException e) {
//     if (e.response != null) {
//       final statusCode = e.response!.statusCode ?? 0;
//       final message = e.response!.data is Map
//           ? e.response!.data['message'] as String? ?? 'An error occurred'
//           : 'An error occurred';
//       return AppException(message: message, statusCode: statusCode);
//     }
//
//     if (e.type == DioExceptionType.connectionTimeout ||
//         e.type == DioExceptionType.receiveTimeout ||
//         e.type == DioExceptionType.sendTimeout) {
//       return const AppException(
//         message: 'Request timed out. Please check your connection.',
//       );
//     }
//
//     if (e.type == DioExceptionType.connectionError) {
//       return const AppException(
//         message: 'No internet connection.',
//       );
//     }
//
//     return AppException(message: e.message ?? 'An unexpected error occurred.');
//   }
// }

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