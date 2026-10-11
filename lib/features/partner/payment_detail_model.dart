/// Partner payment details — admin views read-only
class PartnerPaymentDetail {
  const PartnerPaymentDetail({
    required this.id,
    required this.partnerId,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String partnerId;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PartnerPaymentDetail.fromJson(Map<String, dynamic> j) =>
      PartnerPaymentDetail(
        id: j['id'] as String? ?? '',
        partnerId: j['partnerId'] as String? ?? '',
        bankName: j['bankName'] as String? ?? '',
        accountNumber: j['accountNumber'] as String? ?? '',
        accountName: j['accountName'] as String? ?? '',
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
        updatedAt: j['updatedAt'] != null
            ? DateTime.tryParse(j['updatedAt'].toString())
            : null,
      );
}

/// Audit log entry for payment detail changes
class PaymentDetailHistory {
  const PaymentDetailHistory({
    required this.id,
    required this.partnerId,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.changedAt,
    required this.changedBy,
    this.ipAddress,
  });

  final String id;
  final String partnerId;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final DateTime changedAt;
  final String changedBy;
  final String? ipAddress;

  factory PaymentDetailHistory.fromJson(Map<String, dynamic> j) =>
      PaymentDetailHistory(
        id: j['id'] as String? ?? '',
        partnerId: j['partnerId'] as String? ?? '',
        bankName: j['bankName'] as String? ?? '',
        accountNumber: j['accountNumber'] as String? ?? '',
        accountName: j['accountName'] as String? ?? '',
        changedAt: DateTime.parse(j['changedAt'] as String),
        changedBy: j['changedBy'] as String? ?? '',
        ipAddress: j['ipAddress'] as String?,
      );
}
