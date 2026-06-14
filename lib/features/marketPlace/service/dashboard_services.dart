import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

/// Lightweight stats object for the marketplace dashboard tab.
class MarketDashboardStats {
  const MarketDashboardStats({
    required this.pendingVendors,
    required this.activeAppeals,
    required this.totalAvailableBalance,
    required this.totalLockedBalance,
    required this.successTxCount,
    required this.successTxVolume,
  });

  final int pendingVendors;
  final int activeAppeals;
  final double totalAvailableBalance;
  final double totalLockedBalance;
  final int successTxCount;
  final double successTxVolume;
}

class MarketDashboardService {
  /// Pulls data from two existing endpoints in parallel and merges them
  /// into a single [MarketDashboardStats] object.
  Future<MarketDashboardStats> getStats() async {
    // Fire both requests simultaneously
    final results = await Future.wait([
      DioClient.get(ApiConstants.marketPlaceGetVendors, queryParameters: {'status' : "pending"}),   // list of pending vendors
      DioClient.get(ApiConstants.marketPlaceGetAppeals),           // list of active appeals
      DioClient.get(ApiConstants.adminStats),              // global admin stats
    ]);

    final pendingVendors = (results[0] as List).length;
    final activeAppeals = (results[1] as List).length;

    final adminStats = results[2] as Map<String, dynamic>;
    final balances = adminStats['balances'] as Map<String, dynamic>? ?? {};
    final txMap = adminStats['transactions'] as Map<String, dynamic>? ?? {};
    final successTx = txMap['success'] as Map<String, dynamic>? ?? {};

    return MarketDashboardStats(
      pendingVendors: pendingVendors,
      activeAppeals: activeAppeals,
      totalAvailableBalance:
      (balances['totalAvailable'] as num?)?.toDouble() ?? 0,
      totalLockedBalance:
      (balances['totalLocked'] as num?)?.toDouble() ?? 0,
      successTxCount: (successTx['count'] as num?)?.toInt() ?? 0,
      successTxVolume: (successTx['volume'] as num?)?.toDouble() ?? 0,
    );
  }
}