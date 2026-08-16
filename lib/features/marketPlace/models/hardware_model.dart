// Admin hardware models (Workstream A4) — mirror the amril-api admin payloads.

import 'vendor_model.dart';

class HwProduct {
  final String id;
  final String tier; // budget | premium
  final String category; // bundle | addon
  final String sku;
  final String name;
  final String description;
  final List<String> images;
  final int priceNaira;
  final int? brandingUpchargeNaira;
  final List<String> bulletPoints;
  final bool isActive;
  final int sortOrder;

  HwProduct({
    required this.id,
    required this.tier,
    required this.category,
    required this.sku,
    required this.name,
    required this.description,
    required this.images,
    required this.priceNaira,
    required this.brandingUpchargeNaira,
    required this.bulletPoints,
    required this.isActive,
    required this.sortOrder,
  });

  bool get isAddon => category == 'addon';
  bool get isBundle => category == 'bundle';
  bool get isPremium => tier == 'premium';

  factory HwProduct.fromJson(Map<String, dynamic> j) => HwProduct(
        id: j['id'],
        tier: j['tier'] ?? 'budget',
        category: j['category'] ?? 'bundle',
        sku: j['sku'] ?? '',
        name: j['name'] ?? '',
        description: j['description'] ?? '',
        images: (j['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
        priceNaira: (j['priceNaira'] as num?)?.toInt() ?? 0,
        brandingUpchargeNaira: (j['brandingUpchargeNaira'] as num?)?.toInt(),
        bulletPoints:
            (j['bulletPoints'] as List?)?.map((e) => e.toString()).toList() ?? [],
        isActive: j['isActive'] ?? true,
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
      );
}

class HwBatch {
  final String id;
  final String tier;
  final int moqTarget;
  final int reservedCount;
  final int paidCount;
  final String state;
  final String? etaNote;

  /// Per-product batch link (§3). Null on legacy tier-wide batches — those are
  /// labeled "Legacy (tier-wide)" in the UI and new orders never join them.
  final String? productId;
  final String? productName;

  /// Member-order count from listBatches `_count.orders`.
  final int orderCount;

  HwBatch({
    required this.id,
    required this.tier,
    required this.moqTarget,
    required this.reservedCount,
    required this.paidCount,
    required this.state,
    required this.etaNote,
    required this.productId,
    required this.productName,
    required this.orderCount,
  });

  bool get isLegacy => productId == null;

  /// Catalog progress counts reservations AND paid units (§2.3).
  int get progressCount => reservedCount + paidCount;

  double get progress =>
      moqTarget <= 0 ? 0 : (progressCount / moqTarget).clamp(0, 1).toDouble();

  factory HwBatch.fromJson(Map<String, dynamic> j) => HwBatch(
        id: j['id'],
        tier: j['tier'] ?? 'budget',
        moqTarget: (j['moqTarget'] as num?)?.toInt() ?? 500,
        reservedCount: (j['reservedCount'] as num?)?.toInt() ?? 0,
        paidCount: (j['paidCount'] as num?)?.toInt() ?? 0,
        state: j['state'] ?? 'collecting',
        etaNote: j['etaNote'],
        productId: j['productId'] ?? j['product']?['id'],
        productName: j['product']?['name'],
        orderCount: (j['_count']?['orders'] as num?)?.toInt() ?? 0,
      );
}

class HwOrder {
  final String id;
  final int quantity;
  final bool withBranding;
  final String status;
  final String mode;
  final int? amountNaira;
  final String? batchId;
  final String? cancelReason;
  final String productName;
  final String? productTier;
  final String vendorName;
  final DateTime? createdAt;

  /// Light vendor row (§4.2 — the admin `listOrders` include is now a slim
  /// `{id,name,logo,status}` select). The board opens VendorDetailScreen by id,
  /// which fetches the full record. Null only if an older payload omitted it.
  final VendorLite? vendor;

  HwOrder({
    required this.id,
    required this.quantity,
    required this.withBranding,
    required this.status,
    required this.mode,
    required this.amountNaira,
    required this.batchId,
    required this.cancelReason,
    required this.productName,
    required this.productTier,
    required this.vendorName,
    required this.createdAt,
    required this.vendor,
  });

  factory HwOrder.fromJson(Map<String, dynamic> j) {
    VendorLite? vendor;
    final v = j['vendor'];
    if (v is Map<String, dynamic>) {
      try {
        vendor = VendorLite.fromJson(v);
      } catch (_) {
        vendor = null;
      }
    }
    return HwOrder(
      id: j['id'],
      quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      withBranding: j['withBranding'] ?? false,
      status: j['status'] ?? 'reserved',
      mode: j['mode'] ?? 'reservation',
      amountNaira: (j['amountNaira'] as num?)?.toInt(),
      batchId: j['batchId'],
      cancelReason: j['cancelReason'],
      productName: (j['product']?['name']) ?? 'Product',
      productTier: j['product']?['tier'],
      vendorName: (j['vendor']?['name']) ?? 'Vendor',
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'].toString())
          : null,
      vendor: vendor,
    );
  }

  static const statuses = [
    'awaitingPayment',
    'reserved',
    'paid',
    'inProduction',
    'shipping',
    'atHub',
    'delivered',
    'installed',
    'cancelled',
  ];
}

const hwBatchStates = [
  'collecting',
  'producing',
  'shipping',
  'fulfilling',
  'closed',
];

const hwTiers = ['budget', 'premium', 'kiosk', 'tab'];
const hwCategories = ['bundle', 'addon'];
