// REPO PATH: lib/features/reconciliation/service.dart   (NEW FILE — admin_panel)
//
// Thin data layer over DioClient. Mirrors the other feature services
// (DashboardService, ConfigService): static DioClient.get/post, decode, map to
// a typed model. No business logic here.

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'model.dart';

class TreasuryService {
  /// Live read-only computation. Optional manual balances are passed as query
  /// params so the admin can preview "what if" figures before saving.
  Future<TreasurySummary> getSummary({
    double? opay,
    double? monnify,
    double? bank,
    double? vtpass,
    double? apple,
    double? google,
  }) async {
    final q = <String, dynamic>{};
    if (opay != null) q['opay'] = opay;
    if (monnify != null) q['monnify'] = monnify;
    if (bank != null) q['bank'] = bank;
    if (vtpass != null) q['vtpass'] = vtpass;
    if (apple != null) q['apple'] = apple;
    if (google != null) q['google'] = google;

    final data = await DioClient.get(
      ApiConstants.adminReconciliationSummary,
      queryParameters: q.isEmpty ? null : q,
    );
    return TreasurySummary.fromJson(data as Map<String, dynamic>);
  }

  /// Compute + persist a snapshot. The POST response is { snapshot, computed };
  /// we return the freshly-computed figures.
  Future<TreasurySummary> takeSnapshot({
    double? opay,
    double? monnify,
    double? bank,
    double? vtpass,
    double? apple,
    double? google,
    String? note,
  }) async {
    final data = await DioClient.post(
      ApiConstants.adminReconciliationSnapshot,
      data: {
        if (opay != null) 'opayBalance': opay,
        if (monnify != null) 'monnifyOverride': monnify,
        if (bank != null) 'bankBalance': bank,
        if (vtpass != null) 'vtpassBalance': vtpass,
        if (apple != null) 'appleBalance': apple,
        if (google != null) 'googleBalance': google,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    final map = data as Map<String, dynamic>;
    return TreasurySummary.fromJson(map['computed'] as Map<String, dynamic>);
  }
}