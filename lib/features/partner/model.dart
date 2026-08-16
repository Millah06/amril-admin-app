// ── Partner models for admin panel ───────────────────────────────────────────

class PartnerLite {
  const PartnerLite({
    required this.id,
    required this.name,
    required this.partnerCode,
    this.certificateNumber = '',
    this.phone = '',
    this.email = '',
    this.tier = 'PARTNER',
    this.status = 'active',
    this.commissionRate = 1,
    this.vendorLinkCount = 0,
    this.userId,
    this.createdAt,
  });

  final String id;
  final String name;
  final String partnerCode;
  final String certificateNumber;
  final String phone;
  final String email;
  final String tier;
  final String status;
  final double commissionRate;
  final int vendorLinkCount;
  final String? userId;
  final DateTime? createdAt;

  bool get isActive => status == 'active';

  factory PartnerLite.fromJson(Map<String, dynamic> j) => PartnerLite(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        partnerCode: j['partnerCode'] as String? ?? '',
        certificateNumber: j['certificateNumber'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        email: j['email'] as String? ?? '',
        tier: j['tier'] as String? ?? 'PARTNER',
        status: j['status'] as String? ?? 'active',
        commissionRate: (j['commissionRate'] as num?)?.toDouble() ?? 1,
        vendorLinkCount:
            (j['_count']?['vendorLinks'] as num?)?.toInt() ?? 0,
        userId: j['userId'] as String?,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
      );
}

class PartnerVendorLink {
  const PartnerVendorLink({
    required this.id,
    required this.partnerId,
    required this.vendorId,
    required this.assignedAt,
    required this.expiresAt,
    this.vendorName = '',
    this.vendorLogo = '',
    this.vendorStatus = '',
    this.vendorType = '',
    this.branchCount = 0,
  });

  final String id;
  final String partnerId;
  final String vendorId;
  final DateTime assignedAt;
  final DateTime expiresAt;
  final String vendorName;
  final String vendorLogo;
  final String vendorStatus;
  final String vendorType;
  final int branchCount;

  bool get isActive => expiresAt.isAfter(DateTime.now());

  factory PartnerVendorLink.fromJson(Map<String, dynamic> j) {
    final v = j['vendor'] as Map<String, dynamic>? ?? {};
    return PartnerVendorLink(
      id: j['id'] as String,
      partnerId: j['partnerId'] as String? ?? '',
      vendorId: j['vendorId'] as String? ?? '',
      assignedAt: DateTime.parse(j['assignedAt'].toString()),
      expiresAt: DateTime.parse(j['expiresAt'].toString()),
      vendorName: v['name'] as String? ?? '',
      vendorLogo: v['logo'] as String? ?? '',
      vendorStatus: v['status'] as String? ?? '',
      vendorType: v['vendorType'] as String? ?? '',
      branchCount: (v['_count']?['branches'] as num?)?.toInt() ?? 0,
    );
  }
}

class PartnerPayout {
  const PartnerPayout({
    required this.id,
    required this.partnerId,
    required this.month,
    required this.year,
    required this.transactionAmount,
    required this.commissionRate,
    required this.commissionAmount,
    required this.status,
    this.paidAt,
    this.note,
    this.createdAt,
  });

  final String id;
  final String partnerId;
  final int month;
  final int year;
  final double transactionAmount;
  final double commissionRate;
  final double commissionAmount;
  final String status; // PENDING | PAID | CANCELLED
  final DateTime? paidAt;
  final String? note;
  final DateTime? createdAt;

  factory PartnerPayout.fromJson(Map<String, dynamic> j) => PartnerPayout(
        id: j['id'] as String,
        partnerId: j['partnerId'] as String? ?? '',
        month: (j['month'] as num?)?.toInt() ?? 1,
        year: (j['year'] as num?)?.toInt() ?? 2026,
        transactionAmount:
            (j['transactionAmount'] as num?)?.toDouble() ?? 0,
        commissionRate: (j['commissionRate'] as num?)?.toDouble() ?? 1,
        commissionAmount:
            (j['commissionAmount'] as num?)?.toDouble() ?? 0,
        status: j['status'] as String? ?? 'PENDING',
        paidAt: j['paidAt'] != null
            ? DateTime.tryParse(j['paidAt'].toString())
            : null,
        note: j['note'] as String?,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
      );
}

class PartnerDetail {
  const PartnerDetail({
    required this.id,
    required this.name,
    required this.partnerCode,
    this.certificateNumber = '',
    this.phone = '',
    this.email = '',
    this.tier = 'PARTNER',
    this.status = 'active',
    this.commissionRate = 1,
    this.userId,
    this.vendorLinks = const [],
    this.payouts = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final String partnerCode;
  final String certificateNumber;
  final String phone;
  final String email;
  final String tier;
  final String status;
  final double commissionRate;
  final String? userId;           // null = not yet linked to a User account
  final List<PartnerVendorLink> vendorLinks;
  final List<PartnerPayout> payouts;
  final DateTime? createdAt;

  bool get isActive => status == 'active';
  bool get hasUserAccount => userId != null;

  factory PartnerDetail.fromJson(Map<String, dynamic> j) => PartnerDetail(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        partnerCode: j['partnerCode'] as String? ?? '',
        certificateNumber: j['certificateNumber'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        email: j['email'] as String? ?? '',
        tier: j['tier'] as String? ?? 'PARTNER',
        status: j['status'] as String? ?? 'active',
        commissionRate: (j['commissionRate'] as num?)?.toDouble() ?? 1,
        userId: j['userId'] as String?,
        vendorLinks: ((j['vendorLinks'] as List?) ?? [])
            .map((e) => PartnerVendorLink.fromJson(e as Map<String, dynamic>))
            .toList(),
        payouts: ((j['payouts'] as List?) ?? [])
            .map((e) => PartnerPayout.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
      );
}

/// Summary returned by GET /admin/partners/:id/commission
class CommissionSummary {
  const CommissionSummary({
    required this.partnerId,
    required this.partnerName,
    required this.partnerCode,
    required this.month,
    required this.year,
    required this.vendorCount,
    required this.activeVendorCount,
    required this.eligibleVendorCount,
    required this.transactionCount,
    required this.eligibleVolume,
    required this.excludedAmount,
    required this.commissionRate,
    required this.calculatedCommission,
    this.existingPayout,
    this.vendorBreakdown = const [],
  });

  final String partnerId;
  final String partnerName;
  final String partnerCode;
  final int month;
  final int year;
  final int vendorCount;
  final int activeVendorCount;
  final int eligibleVendorCount;
  final int transactionCount;
  final double eligibleVolume;
  final double excludedAmount;
  final double commissionRate;
  final double calculatedCommission;
  final PartnerPayout? existingPayout;
  final List<Map<String, dynamic>> vendorBreakdown;

  factory CommissionSummary.fromJson(Map<String, dynamic> j) {
    final s = j['summary'] as Map<String, dynamic>? ?? {};
    final p = j['partner'] as Map<String, dynamic>? ?? {};
    final period = j['period'] as Map<String, dynamic>? ?? {};
    final ep = j['existingPayout'];
    return CommissionSummary(
      partnerId: p['id'] as String? ?? '',
      partnerName: p['name'] as String? ?? '',
      partnerCode: p['partnerCode'] as String? ?? '',
      month: (period['month'] as num?)?.toInt() ?? 1,
      year: (period['year'] as num?)?.toInt() ?? 2026,
      vendorCount: (s['vendorCount'] as num?)?.toInt() ?? 0,
      activeVendorCount: (s['activeVendorCount'] as num?)?.toInt() ?? 0,
      eligibleVendorCount: (s['eligibleVendorCount'] as num?)?.toInt() ?? 0,
      transactionCount: (s['transactionCount'] as num?)?.toInt() ?? 0,
      eligibleVolume: (s['eligibleVolume'] as num?)?.toDouble() ?? 0,
      excludedAmount: (s['excludedAmount'] as num?)?.toDouble() ?? 0,
      commissionRate: (s['commissionRate'] as num?)?.toDouble() ?? 1,
      calculatedCommission:
          (s['calculatedCommission'] as num?)?.toDouble() ?? 0,
      existingPayout: ep != null
          ? PartnerPayout.fromJson(ep as Map<String, dynamic>)
          : null,
      vendorBreakdown: ((j['vendorBreakdown'] as List?) ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}
