import 'package:admin_panel/features/marketPlace/models/vendor_model.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class VendorService {

  Future<void> approveVendor(String vendorId) async {
    final data = await DioClient.post(ApiConstants.marketPlaceApproveVendor(vendorId));

  }

  Future<void> rejectVendor(String vendorId, String reason) async {
    await DioClient.post(ApiConstants.marketPlaceRejectVendor(vendorId), data: {'reason' : reason});
  }

  Future<List<VendorModel>> getVendors(String? verificationStatus, String? status, String? vendorType, String? search) async {
    final data = await DioClient.get(
        ApiConstants.marketPlaceGetVendors,
        queryParameters: {
          if (verificationStatus != null) 'verificationStatus': verificationStatus,
          if (status != null) 'status': status,
          if (vendorType != null) 'vendorType': vendorType,
          if (search != null) 'search': search
        }
    );
    return (data as List)
        .map((e) => VendorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}