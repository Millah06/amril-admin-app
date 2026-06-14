/// Represents a Vendor record from the marketplace.
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
    this.branches = const [],
  });

  final String id;
  final String ownerId;
  final String name;
  final String vendorType; // restaurant | grocery | drinks | retail
  final String description;
  final String status;     // pending | approved | rejected
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
  final List<dynamic> branches;

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
    branches: json['branches'] as List<dynamic>? ?? [],
  );
}