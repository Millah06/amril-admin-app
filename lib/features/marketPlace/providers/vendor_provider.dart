import 'package:flutter/foundation.dart';

import '../../../core/erorrs/app_exception.dart';
import '../models/vendor_model.dart';
import '../service/vendor_service.dart';

/// Cursor-paginated vendors list (§4.3 — mirrors the HardwareProvider orders
/// pattern). Filters are always passed server-side; changing one reloads from
/// the first page.
class VendorProvider extends ChangeNotifier {
  VendorProvider(this._service);

  final VendorService _service;

  List<VendorLite> _vendors = [];
  bool _loading = false;
  String? _error;

  String? _cursor;
  bool hasMore = false;
  bool loadingMore = false;

  String? _verificationStatus;
  String? _status;
  String? _type;
  String? _search;

  List<VendorLite> get vendors => _vendors;
  bool get loading => _loading;
  String? get error => _error;
  int get count => _vendors.length;

  // Current server-side filters — the tab chips and the filter sheet both
  // read these so their selections stay in sync (one source of truth).
  String? get statusFilter => _status;
  String? get verificationStatusFilter => _verificationStatus;
  String? get typeFilter => _type;

  bool noFilter() =>
      _verificationStatus == null && _status == null && _type == null;

  Future<void> applyFilter(
      String? verificationStatus, String? status, String? type) async {
    _verificationStatus = verificationStatus;
    _status = status;
    _type = type;
    await load();
  }

  /// Quick-chip filter: change only the status, keep the sheet's
  /// verification/type filters intact.
  Future<void> setStatusFilter(String? status) async {
    _status = status;
    await load();
  }

  Future<void> search(String searchQuery) async {
    _search = searchQuery.trim().isEmpty ? null : searchQuery.trim();
    await load(silent: true);
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final page = await _service.getVendors(
        verificationStatus: _verificationStatus,
        status: _status,
        vendorType: _type,
        search: _search,
      );
      _vendors = page.items;
      _cursor = page.nextCursor;
      hasMore = page.hasMore;
      _error = null;
    } on AppException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore || _cursor == null) return;
    loadingMore = true;
    notifyListeners();
    try {
      final page = await _service.getVendors(
        verificationStatus: _verificationStatus,
        status: _status,
        vendorType: _type,
        search: _search,
        cursor: _cursor,
      );
      _vendors = [..._vendors, ...page.items];
      _cursor = page.nextCursor;
      hasMore = page.hasMore;
    } on AppException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  /// Full record for the detail screen (branches + trustProfile + counts).
  Future<VendorModel> getDetail(String vendorId) =>
      _service.getVendorDetail(vendorId);

  /// Approve a vendor. Reloads the current page on success.
  /// Returns an error message string, or null on success.
  Future<String?> approve(String vendorId) =>
      _mutate(() => _service.approveVendor(vendorId));

  /// Reject a vendor with a reason.
  Future<String?> reject(String vendorId, {required String reason}) =>
      _mutate(() => _service.rejectVendor(vendorId, reason));

  /// Suspend an approved vendor with a reason (§4.2).
  Future<String?> suspend(String vendorId, {required String reason}) =>
      _mutate(() => _service.suspendVendor(vendorId, reason));

  /// Reinstate a suspended vendor back to approved.
  Future<String?> reinstate(String vendorId) =>
      _mutate(() => _service.reinstateVendor(vendorId));

  Future<String?> _mutate(Future<void> Function() op) async {
    try {
      await op();
      await load(silent: true);
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}
