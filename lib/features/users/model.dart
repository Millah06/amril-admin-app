/// Represents a user record from GET /admin/users
class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.active,
    required this.transferUid,
    required this.createdAt,
    this.kycStatus,
    this.avatarUrl,
    this.isVerified = false,
    this.availableBalance,
    this.lockedBalance,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool active;
  final String transferUid;
  final DateTime createdAt;
  final String? kycStatus;
  final String? avatarUrl;
  final bool isVerified;
  final double? availableBalance;
  final double? lockedBalance;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final profile = json['userProfile'] as Map<String, dynamic>?;
    final fiat = (json['wallet'] as Map<String, dynamic>?)?['fiat'] as Map<String, dynamic>?;
    final kyc = json['kyc'] as Map<String, dynamic>?;

    return AdminUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String,
      active: json['active'] as bool,
      transferUid: json['transferUid'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      kycStatus: kyc?['status'] as String?,
      avatarUrl: profile?['avatarUrl'] as String?,
      isVerified: profile?['isVerified'] as bool? ?? false,
      availableBalance: (fiat?['availableBalance'] as num?)?.toDouble(),
      lockedBalance: (fiat?['lockedBalance'] as num?)?.toDouble(),
    );
  }
}

class PaginatedUsers {
  const PaginatedUsers({
    required this.data,
    required this.total,
    required this.page,
    required this.pages,
  });

  final List<AdminUser> data;
  final int total;
  final int page;
  final int pages;

  factory PaginatedUsers.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;
    return PaginatedUsers(
      data: (json['data'] as List)
          .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      pages: (meta['pages'] as num).toInt(),
    );
  }

  bool get hasNextPage => page < pages;
}