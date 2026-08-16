import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class BroadcastService {
  /// POST /chat/official/broadcast
  /// Sends a real FCM topic push to ALL signed-in devices AND appends the
  /// message to the official_broadcast Firestore collection (chat channel).
  Future<Map<String, dynamic>> send({
    required String message,
    String? title,
    String? imageUrl,
    String? route,
  }) async {
    final data = await DioClient.post(
      ApiConstants.broadcastSend,
      data: {
        'message': message,
        if (title != null && title.isNotEmpty) 'title': title,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        if (route != null && route.isNotEmpty) 'route': route,
      },
    );
    return Map<String, dynamic>.from(data as Map);
  }
}
