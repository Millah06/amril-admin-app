import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/appeal_model.dart';

class AppealService {
  /// GET /admin/order/appeals
  Future<List<AppealOrder>> getAppeals() async {
    final data = await DioClient.get(ApiConstants.marketPlaceGetAppeals);
    return (data as List)
        .map((e) => AppealOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /admin/order/:id/resolve
  /// [decision] must be 'release_vendor' or 'refund_user'
  Future<void> resolveAppeal({
    required String orderId,
    required String decision,
    String? reason,
  }) async {
    await DioClient.post(
      ApiConstants.marketPlaceResolveAppeal(orderId),
      data: {
        'decision': decision,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  /// POST /admin/chat/:orderId/send
  /// Sends an admin message into the Firestore chat for an order.
  Future<void> sendChatMessage({
    required String orderId,
    required String message,
  }) async {
    try {
      final data = await DioClient.post(
        ApiConstants.marketPlaceSendMessage(orderId),
        data: {'message': message},
      );
      print('🔥🔥 $data');
    }
    catch (e) {
      print('🔥🔥 $e');
    }
  }

}