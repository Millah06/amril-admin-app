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
  static String marketPlaceVendorDetail(String vendorId) => '/admin/vendor/$vendorId';
  static String marketPlaceApproveVendor(String vendorId) => '/admin/vendor/$vendorId/approve';
  static String marketPlaceRejectVendor(String vendorId) => '/admin/vendor/$vendorId/reject';
  static String marketPlaceSuspendVendor(String vendorId) => '/admin/vendor/$vendorId/suspend';
  static String marketPlaceReinstateVendor(String vendorId) => '/admin/vendor/$vendorId/reinstate';


  // ── MarketPlace: Appeal ──────────────────────────────────────────────────────
  static const String marketPlaceGetAppeals = '/admin/order/appeals';
  static String marketPlaceResolveAppeal(String orderId) => '/admin/order/$orderId/resolve';
  static String marketPlaceSendMessage(String orderId) => '/admin/chat/$orderId/send';

  // ── MarketPlace: Config ──────────────────────────────────────────────────────
  static const String marketPlaceGetConfig = '/admin/config';
  static const String marketPlaceUpdateConfig = '/admin/config';

  // ── MarketPlace: Hardware (Workstream A4) ────────────────────────────────────
  static const String hardwareProducts = '/admin/hardware/products';
  static const String hardwareCreateProduct = '/admin/hardware/product';
  static String hardwareUpdateProduct(String id) => '/admin/hardware/product/$id';
  static String hardwareProductImages(String id) => '/admin/hardware/product/$id/images';
  static String hardwareDeleteProduct(String id) => '/admin/hardware/product/$id';
  static const String hardwareOrders = '/admin/hardware/orders';
  static String hardwareUpdateOrder(String id) => '/admin/hardware/order/$id';
  static const String hardwareBatches = '/admin/hardware/batches';
  static const String hardwareCreateBatch = '/admin/hardware/batch';
  static String hardwareUpdateBatch(String id) => '/admin/hardware/batch/$id';
  static String hardwareBatchOrders(String id) => '/admin/hardware/batch/$id/orders';

  // ── Admin: Reconciliation / Treasury ──────────────────────────────────────
  static const String adminReconciliationSummary  = '/admin/reconciliation/summary';
  static const String adminReconciliationSnapshot = '/admin/reconciliation/snapshot';
  static const String adminReconciliationHistory  = '/admin/reconciliation/history';
  static const String adminRevenueSummary         = '/admin/revenue/summary';
  static const String adminRevenueLedger          = '/admin/revenue/ledger';

  // ── Broadcast ─────────────────────────────────────────────────────────────
  /// POST /chat/official/broadcast — admin-only FCM topic push + Firestore doc.
  static const String broadcastSend = '/chat/official/broadcast';

  // ── Partner acquisition system ────────────────────────────────────────────
  static const String adminPartners = '/admin/partners';
  static String adminPartnerDetail(String id) => '/admin/partners/$id';
  static String adminPartnerUpdate(String id) => '/admin/partners/$id';
  static String adminPartnerLinkUser(String id) => '/admin/partners/$id/link-user';
  static String adminPartnerVendors(String id) => '/admin/partners/$id/vendors';
  static String adminPartnerVendorLink(String id, String linkId) =>
      '/admin/partners/$id/vendors/$linkId';
  static String adminPartnerCommission(String id) =>
      '/admin/partners/$id/commission';
  static String adminPartnerPayouts(String id) =>
      '/admin/partners/$id/payouts';
  static String adminPartnerPayoutDetail(String id, String payoutId) =>
      '/admin/partners/$id/payouts/$payoutId';
}