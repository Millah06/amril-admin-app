import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

import 'model.dart';

class TransactionsService {
  Future<PaginatedTransactions> getTransactions({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
    String? userId,
    DateTime? from,
    DateTime? to,
  }) async {
    final data = await DioClient.get(
      ApiConstants.adminTransactions,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
        if (type != null) 'type': type,
        if (userId != null) 'userId': userId,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
    );
    return PaginatedTransactions.fromJson(data as Map<String, dynamic>);
  }

  Future<AdminTransaction> searchByRef(String ref) async {
    final data = await DioClient.get(
      ApiConstants.adminTransactionSearch,
      queryParameters: {'ref': ref},
    );
    return AdminTransaction.fromJson(data as Map<String, dynamic>);
  }

  Future<String> refund(String transactionId, {String? reason}) async {
    final data = await DioClient.post(
      ApiConstants.adminRefund(transactionId),
      data: {if (reason != null) 'reason': reason},
    );
    return (data as Map<String, dynamic>)['refundRef'] as String;
  }
}