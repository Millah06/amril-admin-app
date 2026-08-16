import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/hardware_model.dart';
import '../service/hardware_service.dart';

class HardwareProvider extends ChangeNotifier {
  HardwareProvider(this._service);
  final HardwareService _service;

  List<HwProduct> products = [];
  List<HwBatch> batches = [];
  List<HwOrder> orders = [];

  bool loading = false;
  String? error;

  // ── Orders pagination state ──
  String? _ordersCursor;
  bool ordersHasMore = false;
  bool ordersLoadingMore = false;
  String? _ordersStatusFilter;

  /// Orders-board-only error (kept separate from [error] so a failed orders
  /// refresh doesn't blank the products/batches sections) — backs the
  /// empty-state Retry button (§WS6.2).
  String? ordersError;

  /// Currently selected `?status=` filter (null = all) — drives the chips row.
  String? get ordersStatusFilter => _ordersStatusFilter;

  Future<void> loadAll() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      products = await _service.getProducts();
      batches = await _service.getBatches();
      await _loadOrdersFirstPage();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    products = await _service.getProducts();
    notifyListeners();
  }

  Future<void> loadBatches() async {
    batches = await _service.getBatches();
    notifyListeners();
  }

  // ── Orders ──
  Future<void> _loadOrdersFirstPage() async {
    try {
      final page =
          await _service.getOrders(status: _ordersStatusFilter, limit: 20);
      orders = page.items;
      _ordersCursor = page.nextCursor;
      ordersHasMore = page.hasMore;
      ordersError = null;
    } catch (e) {
      orders = [];
      _ordersCursor = null;
      ordersHasMore = false;
      ordersError = e.toString().replaceAll('Exception: ', '');
      rethrow;
    }
  }

  /// Reload the orders board from the first page (e.g. pull-to-refresh or after
  /// a status change). Optionally set a [status] filter (null = all).
  Future<void> reloadOrders({String? status, bool resetFilter = false}) async {
    if (resetFilter) _ordersStatusFilter = status;
    try {
      await _loadOrdersFirstPage();
    } catch (_) {
      // ordersError already set; keep the global error clear so the other
      // sections stay usable.
    }
    notifyListeners();
  }

  /// Change the `?status=` chip filter and reload from the first page (§2.7).
  Future<void> setOrdersStatusFilter(String? status) =>
      reloadOrders(status: status, resetFilter: true);

  Future<void> loadMoreOrders() async {
    if (ordersLoadingMore || !ordersHasMore || _ordersCursor == null) return;
    ordersLoadingMore = true;
    notifyListeners();
    try {
      final page = await _service.getOrders(
        cursor: _ordersCursor,
        status: _ordersStatusFilter,
        limit: 20,
      );
      orders = [...orders, ...page.items];
      _ordersCursor = page.nextCursor;
      ordersHasMore = page.hasMore;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      ordersLoadingMore = false;
      notifyListeners();
    }
  }

  /// One page of a batch's member orders (§3 "View orders (N)"). Stateless
  /// passthrough — the batch-orders screen owns its own pagination state.
  Future<HwOrderPage> getBatchOrders(String batchId,
          {String? cursor, int limit = 20}) =>
      _service.getBatchOrders(batchId, cursor: cursor, limit: limit);

  // ── Products ──
  Future<String?> saveProduct(Map<String, dynamic> body, {String? id}) =>
      _run(() => id == null
          ? _service.createProduct(body)
          : _service.updateProduct(id, body));

  /// Full product save used by the dedicated edit screen:
  ///  1. create or update the row (with [keptImageUrls] as the images array so
  ///     removed existing images are dropped),
  ///  2. upload any [newImages] to the (now-known) product id.
  /// Returns null on success or an error string.
  Future<String?> saveProductWithImages({
    String? id,
    required Map<String, dynamic> body,
    required List<String> keptImageUrls,
    required List<XFile> newImages,
  }) async {
    try {
      final withImages = {...body, 'images': keptImageUrls};
      final saved = id == null
          ? await _service.createProduct(withImages)
          : await _service.updateProduct(id, withImages);
      if (newImages.isNotEmpty) {
        await _service.uploadProductImages(saved.id, newImages);
      }
      await loadAll();
      return null;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      error = msg;
      notifyListeners();
      return msg;
    }
  }

  Future<String?> deleteProduct(String id) =>
      _run(() => _service.deleteProduct(id));

  // ── Batches ──
  Future<String?> saveBatch(Map<String, dynamic> body, {String? id}) =>
      _run(() => id == null
          ? _service.createBatch(body)
          : _service.updateBatch(id, body));

  // ── Orders ──
  Future<String?> updateOrder(String id, Map<String, dynamic> body) async {
    try {
      await _service.updateOrder(id, body);
      // Only the orders board changes; refresh it (and batches, since a batch
      // state change can cascade — cheap to refetch) without a full reload.
      await reloadOrders();
      return null;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      error = msg;
      notifyListeners();
      return msg;
    }
  }

  /// Runs a mutation then reloads everything; returns null on success or an
  /// error string. Used for product/batch create/edit/delete where a batch
  /// state change may auto-advance member orders (§2.2).
  Future<String?> _run(Future<void> Function() op) async {
    try {
      await op();
      await loadAll();
      return null;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      error = msg;
      notifyListeners();
      return msg;
    }
  }
}
