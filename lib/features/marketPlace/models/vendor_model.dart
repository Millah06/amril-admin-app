/// Slim vendor row from the paginated `GET /admin/vendors` list (§4.2 light
/// select) and from the light `vendor` include on hardware orders. Full detail
/// comes from `GET /admin/vendor/:vendorId` → [VendorModel].
class VendorLite {
  const VendorLite({
    required this.id,
    required this.name,
    this.vendorType = 'restaurant',
    this.status = 'pending',
    this.verificationStatus = 'unverified',
    this.verified = false,
    this.logo = '',
    this.email = '',
    this.phone = '',
    this.cac = '',
    this.isVisible = true,
    this.createdAt,
    this.rejectionMessage,
    this.suspensionReason,
    this.branchCount = 0,
  });

  final String id;
  final String name;
  final String vendorType; // restaurant | grocery | drinks | retail
  final String status; // pending | approved | rejected | suspended
  final String verificationStatus;
  final bool verified;
  final String logo;
  final String email;
  final String phone;
  final String cac;
  final bool isVisible;
  final DateTime? createdAt;
  final String? rejectionMessage;
  final String? suspensionReason;
  final int branchCount;

  bool get isSuspended => status == 'suspended';

  factory VendorLite.fromJson(Map<String, dynamic> json) => VendorLite(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Vendor',
        vendorType: json['vendorType'] as String? ?? 'restaurant',
        status: json['status'] as String? ?? 'pending',
        verificationStatus: json['verificationStatus'] as String? ?? 'unverified',
        verified: json['verified'] as bool? ?? false,
        logo: json['logo'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        cac: json['cac'] as String? ?? '',
        isVisible: json['isVisible'] as bool? ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        rejectionMessage: json['rejectionMessage'] as String?,
        suspensionReason: json['suspensionReason'] as String?,
        branchCount: (json['_count']?['branches'] as num?)?.toInt() ?? 0,
      );
}

/// Full Vendor record from `GET /admin/vendor/:vendorId` (branches +
/// trustProfile + order counts included).
class VendorModel {
  const VendorModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.vendorType,
    required this.description,
    required this.status,
    required this.verificationStatus,
    required this.createdAt,
    this.logo = '',
    this.coverPhoto = '',
    this.email = '',
    this.phone = '',
    this.cac = '',
    this.cacCertificateUrl,
    this.rating = 0,
    this.totalCompletedOrders = 0,
    this.completionRate = 100,
    this.verified = false,
    this.isVisible = true,
    this.allowsPayOnDelivery = false,
    this.rejectionMessage,
    this.suspensionReason,
    this.orderCount = 0,
    this.hardwareOrderCount = 0,
    this.branches = const [],
  });

  final String id;
  final String ownerId;
  final String name;
  final String vendorType; // restaurant | grocery | drinks | retail
  final String description;
  final String status;     // pending | approved | rejected | suspended
  final String verificationStatus;
  final DateTime createdAt;
  final String logo;
  final String coverPhoto;
  final String email;
  final String phone;
  final String cac;
  final String? cacCertificateUrl;
  final double rating;
  final int totalCompletedOrders;
  final double completionRate;
  final bool verified;
  final bool isVisible;
  final bool allowsPayOnDelivery;
  final String? rejectionMessage;
  final String? suspensionReason;
  final int orderCount;
  final int hardwareOrderCount;
  final List<dynamic> branches;

  bool get isSuspended => status == 'suspended';

  factory VendorModel.fromJson(Map<String, dynamic> json) => VendorModel(
    id: json['id'] as String,
    ownerId: json['ownerId'] as String,
    name: json['name'] as String,
    vendorType: json['vendorType'] as String? ?? 'restaurant',
    description: json['description'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    verificationStatus: json['verificationStatus'] ?? 'unverified',
    createdAt: DateTime.parse(json['createdAt'] as String),
    logo: json['logo'] as String? ?? '',
    coverPhoto: json['coverPhoto'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    cac: json['cac'] as String? ?? '',
    cacCertificateUrl: json['cacCertificateUrl'] as String?,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    totalCompletedOrders: (json['totalCompletedOrders'] as num?)?.toInt() ?? 0,
    completionRate: (json['completionRate'] as num?)?.toDouble() ?? 100,
    verified: json['verified'] as bool? ?? false,
    isVisible: json['isVisible'] as bool? ?? true,
    allowsPayOnDelivery: json['allowsPayOnDelivery'] as bool? ?? false,
    rejectionMessage: json['rejectionMessage'] as String?,
    suspensionReason: json['suspensionReason'] as String?,
    orderCount: (json['_count']?['orders'] as num?)?.toInt() ?? 0,
    hardwareOrderCount: (json['_count']?['hardwareOrders'] as num?)?.toInt() ?? 0,
    branches: json['branches'] as List<dynamic>? ?? [],
  );
}
