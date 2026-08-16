// REPO PATH: lib/features/reconciliation/model.dart   (NEW FILE — admin_panel)
//
// Typed models for the treasury reconciliation payload returned by
//   GET  /admin/reconciliation/summary
//   POST /admin/reconciliation/snapshot  (under the "computed" key)
//
// The backend shape is { takenAt, ngn:{...}, coin:{...} }. We mirror it 1:1 so
// the screen can read strongly-typed fields instead of poking at maps.

/// Safe number coercion — the JSON may carry int OR double OR null.
double _d(dynamic v) => (v is num) ? v.toDouble() : 0.0;
int _i(dynamic v) => (v is num) ? v.toInt() : 0;
bool _b(dynamic v) => v == true;
String _s(dynamic v) => v?.toString() ?? '';

/// Solvency status for a track. Mirrors the Prisma `ReconStatus` enum.
enum ReconStatus { ok, warn, breach, unknown }

ReconStatus _status(dynamic v) {
  switch (_s(v)) {
    case 'ok':
      return ReconStatus.ok;
    case 'warn':
      return ReconStatus.warn;
    case 'breach':
      return ReconStatus.breach;
    default:
      return ReconStatus.unknown;
  }
}

/// Track A — the NGN wallet float (real Naira held at Paystack + OPay).
class NgnTrack {
  final double userAvailable;
  final double userLocked;
  final double userRewards; // info only
  final double merchantPending;
  final double liabilities;

  final double paystackBalance;
  final bool paystackFetchOk;
  final String paystackReason;
  final double opayBalance;
  final double monnifyBalance;
  final bool monnifyFetchOk;
  final String monnifyReason;
  final double bankBalance;
  final double vtpassBalance;
  final double float;

  final double surplus;
  final double revenueTotal;
  final double unexplainedGap;
  final ReconStatus status;

  NgnTrack({
    required this.userAvailable,
    required this.userLocked,
    required this.userRewards,
    required this.merchantPending,
    required this.liabilities,
    required this.paystackBalance,
    required this.paystackFetchOk,
    required this.paystackReason,
    required this.opayBalance,
    required this.monnifyBalance,
    required this.monnifyFetchOk,
    required this.monnifyReason,
    required this.bankBalance,
    required this.vtpassBalance,
    required this.float,
    required this.surplus,
    required this.revenueTotal,
    required this.unexplainedGap,
    required this.status,
  });

  factory NgnTrack.fromJson(Map<String, dynamic> j) => NgnTrack(
    userAvailable: _d(j['userAvailable']),
    userLocked: _d(j['userLocked']),
    userRewards: _d(j['userRewards']),
    merchantPending: _d(j['merchantPending']),
    liabilities: _d(j['liabilities']),
    paystackBalance: _d(j['paystackBalance']),
    paystackFetchOk: _b(j['paystackFetchOk']),
    paystackReason: _s(j['paystackReason']),
    opayBalance: _d(j['opayBalance']),
    monnifyBalance: _d(j['monnifyBalance']),
    monnifyFetchOk: _b(j['monnifyFetchOk']),
    monnifyReason: _s(j['monnifyReason']),
    bankBalance: _d(j['bankBalance']),
    vtpassBalance: _d(j['vtpassBalance']),
    float: _d(j['float']),
    surplus: _d(j['surplus']),
    revenueTotal: _d(j['revenueTotal']),
    unexplainedGap: _d(j['unexplainedGap']),
    status: _status(j['status']),
  );
}

/// Track B — the coin treasury (the "separate cash-out rail").
class CoinTrack {
  final double conversionRate;
  final double purchaseRate;

  final int ngEarnedCoins;
  final double coinLiability; // NG earned coins × conversionRate (₦)
  final int nonNgEarnedCoins; // info — never converts
  final int purchasedOutstanding; // info — spend-only

  final double coinPurchaseProceedsNg; // earmarked from the PSP float
  final double appleBalance;
  final double googleBalance;
  final double conversionsPaid;
  final double funding;

  final double surplus;
  final double revenueTotal;
  final ReconStatus status;

  CoinTrack({
    required this.conversionRate,
    required this.purchaseRate,
    required this.ngEarnedCoins,
    required this.coinLiability,
    required this.nonNgEarnedCoins,
    required this.purchasedOutstanding,
    required this.coinPurchaseProceedsNg,
    required this.appleBalance,
    required this.googleBalance,
    required this.conversionsPaid,
    required this.funding,
    required this.surplus,
    required this.revenueTotal,
    required this.status,
  });

  factory CoinTrack.fromJson(Map<String, dynamic> j) => CoinTrack(
    conversionRate: _d(j['conversionRate']),
    purchaseRate: _d(j['purchaseRate']),
    ngEarnedCoins: _i(j['ngEarnedCoins']),
    coinLiability: _d(j['coinLiability']),
    nonNgEarnedCoins: _i(j['nonNgEarnedCoins']),
    purchasedOutstanding: _i(j['purchasedOutstanding']),
    coinPurchaseProceedsNg: _d(j['coinPurchaseProceedsNg']),
    appleBalance: _d(j['appleBalance']),
    googleBalance: _d(j['googleBalance']),
    conversionsPaid: _d(j['conversionsPaid']),
    funding: _d(j['funding']),
    surplus: _d(j['surplus']),
    revenueTotal: _d(j['revenueTotal']),
    status: _status(j['status']),
  );
}

/// The full treasury snapshot returned by the API.
class TreasurySummary {
  final String takenAt;
  final NgnTrack ngn;
  final CoinTrack coin;

  TreasurySummary({required this.takenAt, required this.ngn, required this.coin});

  factory TreasurySummary.fromJson(Map<String, dynamic> j) => TreasurySummary(
    takenAt: _s(j['takenAt']),
    ngn: NgnTrack.fromJson((j['ngn'] ?? const {}) as Map<String, dynamic>),
    coin: CoinTrack.fromJson((j['coin'] ?? const {}) as Map<String, dynamic>),
  );
}