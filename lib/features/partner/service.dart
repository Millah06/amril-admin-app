import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'model.dart';

class PartnerService {
  // ── Partners ───────────────────────────────────────────────────────────────

  Future<List<PartnerLite>> getPartners({
    String? search,
    String? status,
    String? cursor,
    int limit = 25,
  }) async {
    final data = await DioClient.get(
      ApiConstants.adminPartners,
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
        if (status != null) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final list = (data['data'] as List?) ?? [];
    return list
        .map((e) => PartnerLite.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PartnerDetail> getPartner(String partnerId) async {
    final data = await DioClient.get(ApiConstants.adminPartnerDetail(partnerId));
    return PartnerDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<PartnerDetail> createPartner({
    required String name,
    String phone = '',
    String email = '',
    String tier = 'PARTNER',
    double commissionRate = 1,
  }) async {
    final data = await DioClient.post(
      ApiConstants.adminPartners,
      data: {
        'name': name,
        'phone': phone,
        'email': email,
        'tier': tier,
        'commissionRate': commissionRate,
      },
    );
    return PartnerDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<PartnerDetail> updatePartner(
    String partnerId, {
    String? name,
    String? phone,
    String? email,
    String? tier,
    String? status,
    double? commissionRate,
  }) async {
    final data = await DioClient.patch(
      ApiConstants.adminPartnerUpdate(partnerId),
      data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (tier != null) 'tier': tier,
        if (status != null) 'status': status,
        if (commissionRate != null) 'commissionRate': commissionRate,
      },
    );
    return PartnerDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<void> linkUserToPartner(String partnerId, String userId) async {
    await DioClient.patch(
      ApiConstants.adminPartnerLinkUser(partnerId),
      data: {'userId': userId},
    );
  }

  // ── Vendor assignments ─────────────────────────────────────────────────────

  Future<PartnerVendorLink> assignVendor(
      String partnerId, String vendorId) async {
    final data = await DioClient.post(
      ApiConstants.adminPartnerVendors(partnerId),
      data: {'vendorId': vendorId},
    );
    return PartnerVendorLink.fromJson(data as Map<String, dynamic>);
  }

  Future<void> removeVendorAssignment(
      String partnerId, String linkId) async {
    await DioClient.delete(
        ApiConstants.adminPartnerVendorLink(partnerId, linkId));
  }

  // ── Commission calculation ─────────────────────────────────────────────────

  Future<CommissionSummary> calculateCommission(
      String partnerId, int month, int year) async {
    final data = await DioClient.get(
      ApiConstants.adminPartnerCommission(partnerId),
      queryParameters: {'month': month, 'year': year},
    );
    return CommissionSummary.fromJson(data as Map<String, dynamic>);
  }

  // ── Payouts ───────────────────────────────────────────────────────────────

  Future<PartnerPayout> createPayout({
    required String partnerId,
    required int month,
    required int year,
    required double transactionAmount,
    required double commissionRate,
    required double commissionAmount,
    String? note,
  }) async {
    final data = await DioClient.post(
      ApiConstants.adminPartnerPayouts(partnerId),
      data: {
        'month': month,
        'year': year,
        'transactionAmount': transactionAmount,
        'commissionRate': commissionRate,
        'commissionAmount': commissionAmount,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return PartnerPayout.fromJson(data as Map<String, dynamic>);
  }

  Future<PartnerPayout> updatePayout({
    required String partnerId,
    required String payoutId,
    String? status,
    String? note,
  }) async {
    final data = await DioClient.patch(
      ApiConstants.adminPartnerPayoutDetail(partnerId, payoutId),
      data: {
        if (status != null) 'status': status,
        if (note != null) 'note': note,
      },
    );
    return PartnerPayout.fromJson(data as Map<String, dynamic>);
  }

  Future<List<PartnerPayout>> getPayouts(String partnerId) async {
    final data = await DioClient.get(
        ApiConstants.adminPartnerPayouts(partnerId));
    return ((data as List?) ?? [])
        .map((e) => PartnerPayout.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
