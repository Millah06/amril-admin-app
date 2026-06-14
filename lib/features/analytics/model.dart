/// Top user ranked by transaction volume
class TopUserByVolume {
  const TopUserByVolume({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.totalVolume,
    required this.transactionCount,
    this.avatarUrl,
  });

  final String userId;
  final String userName;
  final String userEmail;
  final double totalVolume;
  final int transactionCount;
  final String? avatarUrl;

  factory TopUserByVolume.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final profile = user['userProfile'] as Map<String, dynamic>?;
    return TopUserByVolume(
      userId: user['id'] as String,
      userName: user['name'] as String,
      userEmail: user['email'] as String,
      totalVolume: (json['totalVolume'] as num).toDouble(),
      transactionCount: (json['transactionCount'] as num).toInt(),
      avatarUrl: profile?['avatarUrl'] as String?,
    );
  }
}

/// Top user ranked by wallet balance
class TopUserByBalance {
  const TopUserByBalance({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.availableBalance,
    required this.lockedBalance,
    this.avatarUrl,
  });

  final String userId;
  final String userName;
  final String userEmail;
  final double availableBalance;
  final double lockedBalance;
  final String? avatarUrl;

  factory TopUserByBalance.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final profile = user['userProfile'] as Map<String, dynamic>?;
    return TopUserByBalance(
      userId: user['id'] as String,
      userName: user['name'] as String,
      userEmail: user['email'] as String,
      availableBalance: (json['availableBalance'] as num).toDouble(),
      lockedBalance: (json['lockedBalance'] as num? ?? 0).toDouble(),
      avatarUrl: profile?['avatarUrl'] as String?,
    );
  }
}

/// Balance sheet summary from GET /admin/balances/summary
class BalanceSummary {
  const BalanceSummary({
    required this.totalAvailable,
    required this.totalLocked,
    required this.totalRewards,
    required this.averageBalance,
    required this.maxBalance,
    required this.walletsWithPositiveBalance,
  });

  final double totalAvailable;
  final double totalLocked;
  final double totalRewards;
  final double averageBalance;
  final double maxBalance;
  final int walletsWithPositiveBalance;

  factory BalanceSummary.fromJson(Map<String, dynamic> json) => BalanceSummary(
    totalAvailable: (json['totalAvailable'] as num).toDouble(),
    totalLocked: (json['totalLocked'] as num).toDouble(),
    totalRewards: (json['totalRewards'] as num).toDouble(),
    averageBalance: (json['averageBalance'] as num).toDouble(),
    maxBalance: (json['maxBalance'] as num).toDouble(),
    walletsWithPositiveBalance: (json['walletsWithPositiveBalance'] as num).toInt(),
  );
}