/// Represents a transaction record from GET /admin/transactions
class AdminTransaction {
  const AdminTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.transactionRef,
    this.message,
    this.metaData,
    this.userName,
    this.userEmail,
  });

  final String id;
  final String userId;
  final String type;       // "credit" | "debit"
  final double amount;
  final String status;     // "success" | "pending" | "failed"
  final DateTime createdAt;
  final String? transactionRef;
  final String? message;
  final Map<String, dynamic>? metaData;
  // Joined user fields
  final String? userName;
  final String? userEmail;

  bool get isCredit => type == 'credit';
  bool get isSuccess => status == 'success';
  bool get isPending => status == 'pending';
  bool get canBeRefunded => isSuccess && !isCredit;

  factory AdminTransaction.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AdminTransaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      transactionRef: json['transactionRef'] as String?,
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
  });

  final List<AdminTransaction> data;
  final int total;
  final int page;
  final int pages;
  final double totalVolume;

  bool get hasNextPage => page < pages;

  factory PaginatedTransactions.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;
    return PaginatedTransactions(
      data: (json['data'] as List)
          .map((e) => AdminTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      pages: (meta['pages'] as num).toInt(),
      totalVolume: (meta['totalVolume'] as num).toDouble(),
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