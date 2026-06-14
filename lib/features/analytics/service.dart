import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'model.dart';

class AnalyticsService {
  Future<List<TopUserByVolume>> getTopUsersByVolume({
    int limit = 10,
    String? type,
    String period = 'all',
  }) async {
    final data = await DioClient.get(
      ApiConstants.adminTopUsers,
      queryParameters: {
        'limit': limit,
        if (type != null) 'type': type,
        'period': period,
      },
    );
    return (data as List)
        .map((e) => TopUserByVolume.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TopUserByBalance>> getTopUsersByBalance({int limit = 10}) async {
    final data = await DioClient.get(
      ApiConstants.adminTopUsersByBalance,
      queryParameters: {'limit': limit},
    );
    return (data as List)
        .map((e) => TopUserByBalance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BalanceSummary> getBalanceSummary() async {
    final data = await DioClient.get(ApiConstants.adminBalanceSummary);
    return BalanceSummary.fromJson(data as Map<String, dynamic>);
  }
}