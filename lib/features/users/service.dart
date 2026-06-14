import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

import 'model.dart';

class UsersService {
  /// Fetch paginated list of users.
  Future<PaginatedUsers> getUsers({
    int page = 1,
    int limit = 20,
    String? role,
    bool? active,
    String? kycStatus,
    String? search,
  }) async {
    final data = await DioClient.get(
      ApiConstants.adminUsers,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (role != null) 'role': role,
        if (active != null) 'active': active,
        if (kycStatus != null) 'kycStatus': kycStatus,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return PaginatedUsers.fromJson(data as Map<String, dynamic>);
  }

  /// Fetch a single user's full details.
  Future<Map<String, dynamic>> getUserDetail(String userId) async {
    final data = await DioClient.get(ApiConstants.adminUserDetail(userId));
    return data as Map<String, dynamic>;
  }

  /// Block or unblock a user.
  Future<void> setUserActiveStatus({
    required String userId,
    required bool active,
    String? reason,
  }) async {
    await DioClient.patch(
      ApiConstants.adminBlockUser(userId),
      data: {'active': active, if (reason != null) 'reason': reason},
    );
  }

  /// Change user role.
  Future<void> updateRole({
    required String userId,
    required String role,
  }) async {
    await DioClient.patch(
      ApiConstants.adminUserRole(userId),
      data: {'role': role},
    );
  }

  /// Approve or reject KYC.
  Future<void> updateKyc({
    required String userId,
    required String status, // "verified" | "rejected"
    String? reason,
  }) async {
    await DioClient.patch(
      ApiConstants.adminUserKyc(userId),
      data: {'status': status, if (reason != null) 'reason': reason},
    );
  }
}