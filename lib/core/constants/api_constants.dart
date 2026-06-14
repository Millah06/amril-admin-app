/// All API endpoint paths in one place.
/// Change [baseUrl] for different environments.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://everywhere-data-app.onrender.com'; // 🔌 replace with your URL

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';

  // ── Admin: Dashboard ──────────────────────────────────────────────────────
  static const String adminStats = '/admin/stats';
  static const String adminBalanceSummary = '/admin/balances/summary';

  // ── Admin: Users ──────────────────────────────────────────────────────────
  static const String adminUsers = '/admin/users';
  static String adminUserDetail(String id) => '/admin/users/$id';
  static String adminBlockUser(String id) => '/admin/users/$id/block';
  static String adminUserRole(String id) => '/admin/users/$id/role';
  static String adminUserKyc(String id) => '/admin/users/$id/kyc';

  // ── Admin: Transactions ───────────────────────────────────────────────────
  static const String adminTransactions = '/admin/transactions';
  static const String adminTransactionSearch = '/admin/transactions/search';
  static String adminRefund(String id) => '/admin/transactions/$id/refund';
  static const String adminManualCredit = '/admin/transactions/manual-credit';
  static const String adminManualDebit = '/admin/transactions/manual-debit';

  // ── Admin: Analytics ──────────────────────────────────────────────────────
  static const String adminTopUsers = '/admin/top-users';
  static const String adminTopUsersByBalance = '/admin/top-users/balance';

  // ── MarketPlace: DashBoard ──────────────────────────────────────────────────────
  // static const String adminTopUsers = '/admin/top-users';
  // static const String adminTopUsersByBalance = '/admin/top-users/balance';

  // ── MarketPlace: Vendors ──────────────────────────────────────────────────────
  static const String marketPlaceGetVendors = '/admin/vendors';
  static String marketPlaceApproveVendor(String vendorId) => '/admin/vendor/$vendorId/approve';
  static String marketPlaceRejectVendor(String vendorId) => '/admin/vendor/$vendorId/reject';


  // ── MarketPlace: Appeal ──────────────────────────────────────────────────────
  static const String marketPlaceGetAppeals = '/admin/order/appeals';
  static String marketPlaceResolveAppeal(String orderId) => '/admin/order/$orderId/resolve';
  static String marketPlaceSendMessage(String orderId) => '/admin/chat/$orderId/send';

  // ── MarketPlace: Config ──────────────────────────────────────────────────────
  static const String marketPlaceGetConfig = '/admin/config';
  static const String marketPlaceUpdateConfig = '/admin/config';
}