/// Transaction types that represent money coming INTO the wallet.
/// Used as a fallback when the server-computed `direction` is absent
/// (e.g. an older API build that hasn't deployed the field yet).
const _creditTypes = {
  'transfer_credit',
  'wallet_funding',
  'order_refund',
  'manual_credit',
  'credit', // legacy literal, kept for backwards compatibility
};

/// Human-readable labels per transaction type.
const _typeLabels = {
  'wallet_funding': 'Wallet Funded',
  'airtime': 'Airtime Top-Up',
  'data': 'Data Bundle',
  'electricity': 'Electricity',
  'cable': 'Cable TV',
  'transfer_debit': 'Transfer Sent',
  'transfer_credit': 'Transfer Received',
  'order_payment': 'Order Payment',
  'order_refund': 'Order Refund',
  'wallet_withdrawal': 'Wallet Withdrawal',
  'manual_credit': 'Wallet Credit',
  'manual_debit': 'Wallet Debit',
  'verification_fee': 'Business Verification',
  'waec_reg': 'WAEC Registration',
  'waec_result': 'WAEC Result',
  'gift': 'Gift Card',
};

/// Prettifies an unknown type: underscores → spaces, title case.
String _prettifyType(String type) {
  return type
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Represents a transaction record from GET /admin/transactions
class AdminTransaction {
  const AdminTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.direction,
    this.transactionRef,
    this.humanRef,
    this.orderId,
    this.message,
    this.metaData,
    this.userName,
    this.userEmail,
  });

  final String id;
  final String userId;
  final String type;       // e.g. "wallet_funding", "airtime", "transfer_debit"...
  final double amount;
  final String status;     // "success" | "pending" | "failed"
  final DateTime createdAt;
  /// Server-computed, authoritative — "credit" | "debit" — when present.
  final String? direction;
  final String? transactionRef;
  final String? humanRef;
  final String? orderId;
  final String? message;
  final Map<String, dynamic>? metaData;
  // Joined user fields
  final String? userName;
  final String? userEmail;

  /// Prefers the server-computed [direction]; falls back to a local
  /// type-based check when it's absent (older API build).
  bool get isCredit =>
      direction != null ? direction == 'credit' : _creditTypes.contains(type);
  bool get isSuccess => status == 'success';
  bool get isPending => status == 'pending';
  bool get canBeRefunded => isSuccess && !isCredit;

  /// Human label for the transaction type.
  String get displayLabel => _typeLabels[type] ?? _prettifyType(type);

  factory AdminTransaction.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AdminTransaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      direction: json['direction'] as String?,
      transactionRef: json['transactionRef'] as String?,
      humanRef: json['humanRef'] as String?,
      orderId: json['orderId'] as String?,
      message: json['message'] as String?,
      metaData: json['metaData'] as Map<String, dynamic>?,
      userName: user?['name'] as String?,
      userEmail: user?['email'] as String?,
    );
  }
}

class PaginatedTransactions {
  const PaginatedTransactions({
    required this.data,
    required this.total,
    required this.page,
    required this.pages,
    required this.totalVolume,
    this.creditVolume = 0,
    this.debitVolume = 0,
    this.netVolume = 0,
  });

  final List<AdminTransaction> data;
  final int total;
  final int page;
  final int pages;
  final double totalVolume;
  final double creditVolume;
  final double debitVolume;
  final double netVolume;

  bool get hasNextPage => page < pages;

  factory PaginatedTransactions.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;
    final totalVolume = (meta['totalVolume'] as num).toDouble();
    // Tolerate older API builds that don't return the split volumes yet.
    final creditVolume = (meta['creditVolume'] as num?)?.toDouble();
    final debitVolume = (meta['debitVolume'] as num?)?.toDouble();
    final netVolume = (meta['netVolume'] as num?)?.toDouble();
    return PaginatedTransactions(
      data: (json['data'] as List)
          .map((e) => AdminTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      pages: (meta['pages'] as num).toInt(),
      totalVolume: totalVolume,
      creditVolume: creditVolume ?? 0,
      debitVolume: debitVolume ?? 0,
      netVolume: netVolume ?? (creditVolume != null && debitVolume != null
          ? creditVolume - debitVolume
          : totalVolume),
    );
  }
}

class TxFilter {
  const TxFilter({
    this.status,
    this.type,
    this.userId,
    this.from,
    this.to,
    this.ref,
  });

  final String? status;
  final String? type;
  final String? userId;
  final DateTime? from;
  final DateTime? to;
  final String? ref;

  bool get hasFilters =>
      status != null || type != null || userId != null || from != null || to != null;

  static const empty = TxFilter();

  TxFilter copyWith({
    String? status,
    String? type,
    String? userId,
    DateTime? from,
    DateTime? to,
    bool clearStatus = false,
    bool clearType = false,
    bool clearDate = false,
  }) {
    return TxFilter(
      status: clearStatus ? null : (status ?? this.status),
      type: clearType ? null : (type ?? this.type),
      userId: userId ?? this.userId,
      from: clearDate ? null : (from ?? this.from),
      to: clearDate ? null : (to ?? this.to),
    );
  }
}

/// Full user info returned by GET /admin/transactions/:id
class TxUser {
  const TxUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.active,
    this.createdAt,
    this.transferUid,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool? active;
  final DateTime? createdAt;
  final String? transferUid;

  factory TxUser.fromJson(Map<String, dynamic> json) {
    return TxUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      active: json['active'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      transferUid: json['transferUid'] as String?,
    );
  }
}

/// Utility/order delivery info — nullable, present e.g. for electricity purchases.
class TxDelivery {
  const TxDelivery({
    this.status,
    this.token,
    this.tokens,
    this.units,
    this.customerName,
    this.vtpassRef,
    this.productName,
    this.bonusEarned,
  });

  final String? status;
  final String? token;
  final String? tokens;
  final String? units;
  final String? customerName;
  final String? vtpassRef;
  final String? productName;
  final String? bonusEarned;

  factory TxDelivery.fromJson(Map<String, dynamic> json) {
    return TxDelivery(
      status: json['status'] as String?,
      token: json['token'] as String?,
      tokens: json['tokens'] as String?,
      units: json['units'] as String?,
      customerName: json['customerName'] as String?,
      vtpassRef: json['vtpassRef'] as String?,
      productName: json['productName'] as String?,
      bonusEarned: json['bonusEarned']?.toString(),
    );
  }
}

/// Payment provider info — nullable.
class TxPayment {
  const TxPayment({
    this.id,
    this.provider,
    this.providerRef,
    this.status,
    this.entityType,
    this.webhookVerified,
  });

  final String? id;
  final String? provider;
  final String? providerRef;
  final String? status;
  final String? entityType;
  final bool? webhookVerified;

  factory TxPayment.fromJson(Map<String, dynamic> json) {
    return TxPayment(
      id: json['id'] as String?,
      provider: json['provider'] as String?,
      providerRef: json['providerRef'] as String?,
      status: json['status'] as String?,
      entityType: json['entityType'] as String?,
      webhookVerified: json['webhookVerified'] as bool?,
    );
  }
}

/// Refund info — nullable, present when the transaction has been refunded.
class TxRefund {
  const TxRefund({
    this.id,
    this.amount,
    this.transactionRef,
    this.createdAt,
  });

  final String? id;
  final double? amount;
  final String? transactionRef;
  final DateTime? createdAt;

  factory TxRefund.fromJson(Map<String, dynamic> json) {
    return TxRefund(
      id: json['id'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      transactionRef: json['transactionRef'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}

/// Full transaction record from GET /admin/transactions/:id
class AdminTransactionDetail {
  const AdminTransactionDetail({
    required this.tx,
    required this.user,
    this.delivery,
    this.payment,
    this.refund,
  });

  final AdminTransaction tx;
  final TxUser user;
  final TxDelivery? delivery;
  final TxPayment? payment;
  final TxRefund? refund;

  factory AdminTransactionDetail.fromJson(Map<String, dynamic> json) {
    final delivery = json['delivery'] as Map<String, dynamic>?;
    final payment = json['payment'] as Map<String, dynamic>?;
    final refund = json['refund'] as Map<String, dynamic>?;
    return AdminTransactionDetail(
      tx: AdminTransaction.fromJson(json),
      user: TxUser.fromJson(json['user'] as Map<String, dynamic>),
      delivery: delivery != null ? TxDelivery.fromJson(delivery) : null,
      payment: payment != null ? TxPayment.fromJson(payment) : null,
      refund: refund != null ? TxRefund.fromJson(refund) : null,
    );
  }
}