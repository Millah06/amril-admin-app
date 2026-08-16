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
      DioClient.get(ApiConstants.marketPlaceGetVendors,
          queryParameters: {'status': 'pending', 'limit': 50}), // pending vendors (first page)
      DioClient.get(ApiConstants.marketPlaceGetAppeals),           // list of active appeals
      DioClient.get(ApiConstants.adminStats),              // global admin stats
    ]);

    // /admin/vendors returns a `{data, meta}` envelope (§4.2). No total count in
    // meta, so this tile counts the first page (capped at 50) — plenty for a
    // "needs attention" dashboard number.
    final vendorsRes = results[0];
    final pendingVendors = vendorsRes is Map
        ? ((vendorsRes['data'] as List?)?.length ?? 0)
        : (vendorsRes as List).length;
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