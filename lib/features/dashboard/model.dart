/// Dashboard statistics returned by GET /admin/stats
class DashboardStats {
  const DashboardStats({
    required this.users,
    required this.kyc,
    required this.balances,
    required this.transactions,
  });

  final UserStats users;
  final KycStats kyc;
  final BalanceStats balances;
  final Map<String, TxStatusStat> transactions;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final txMap = <String, TxStatusStat>{};
    (json['transactions'] as Map<String, dynamic>? ?? {}).forEach((key, value) {
      txMap[key] = TxStatusStat.fromJson(value as Map<String, dynamic>);
    });
    return DashboardStats(
      users: UserStats.fromJson(json['users'] as Map<String, dynamic>),
      kyc: KycStats.fromJson(json['kyc'] as Map<String, dynamic>),
      balances: BalanceStats.fromJson(json['balances'] as Map<String, dynamic>),
      transactions: txMap,
    );
  }
}

class UserStats {
  const UserStats({
    required this.total,
    required this.active,
    required this.blocked,
    required this.newToday,
  });

  final int total;
  final int active;
  final int blocked;
  final int newToday;

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    total: (json['total'] as num).toInt(),
    active: (json['active'] as num).toInt(),
    blocked: (json['blocked'] as num).toInt(),
    newToday: (json['newToday'] as num).toInt(),
  );
}

class KycStats {
  const KycStats({required this.verified, required this.pending});

  final int verified;
  final int pending;

  factory KycStats.fromJson(Map<String, dynamic> json) => KycStats(
    verified: (json['verified'] as num).toInt(),
    pending: (json['pending'] as num).toInt(),
  );
}

class BalanceStats {
  const BalanceStats({
    required this.totalAvailable,
    required this.totalLocked,
    required this.totalRewards,
  });

  final double totalAvailable;
  final double totalLocked;
  final double totalRewards;

  factory BalanceStats.fromJson(Map<String, dynamic> json) => BalanceStats(
    totalAvailable: (json['totalAvailable'] as num).toDouble(),
    totalLocked: (json['totalLocked'] as num).toDouble(),
    totalRewards: (json['totalRewards'] as num).toDouble(),
  );
}

class TxStatusStat {
  const TxStatusStat({required this.count, required this.volume});

  final int count;
  final double volume;

  factory TxStatusStat.fromJson(Map<String, dynamic> json) => TxStatusStat(
    count: (json['count'] as num).toInt(),
    volume: (json['volume'] as num).toDouble(),
  );
}