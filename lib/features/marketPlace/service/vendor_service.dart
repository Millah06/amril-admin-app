import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/vendor_model.dart';

/// One page of the cursor-paginated vendors list (§4.2 — the api now returns a
/// `{data, meta}` envelope; the old plain-array response is gone).
class VendorPage {
  final List<VendorLite> items;
  final String? nextCursor;
  final bool hasMore;
  VendorPage({required this.items, required this.nextCursor, required this.hasMore});
}

class VendorService {
  Future<void> approveVendor(String vendorId) async {
    await DioClient.post(ApiConstants.marketPlaceApproveVendor(vendorId));
  }

  Future<void> rejectVendor(String vendorId, String reason) async {
    await DioClient.post(ApiConstants.marketPlaceRejectVendor(vendorId),
        data: {'reason': reason});
  }

  Future<void> suspendVendor(String vendorId, String reason) async {
    await DioClient.post(ApiConstants.marketPlaceSuspendVendor(vendorId),
        data: {'reason': reason});
  }

  Future<void> reinstateVendor(String vendorId) async {
    await DioClient.post(ApiConstants.marketPlaceReinstateVendor(vendorId));
  }

  Future<VendorPage> getVendors({
    String? verificationStatus,
    String? status,
    String? vendorType,
    String? search,
    String? cursor,
    int limit = 25,
  }) async {
    final data = await DioClient.get(
      ApiConstants.marketPlaceGetVendors,
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
        if (verificationStatus != null) 'verificationStatus': verificationStatus,
        if (status != null) 'status': status,
        if (vendorType != null) 'vendorType': vendorType,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final list = (data['data'] as List?) ?? [];
    final meta = (data['meta'] as Map?) ?? const {};
    return VendorPage(
      items: list
          .map((e) => VendorLite.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: meta['nextCursor'] as String?,
      hasMore: meta['hasMore'] as bool? ?? false,
    );
  }

  Future<VendorModel> getVendorDetail(String vendorId) async {
    final data = await DioClient.get(ApiConstants.marketPlaceVendorDetail(vendorId));
    return VendorModel.fromJson(data as Map<String, dynamic>);
  }
}
