import 'package:flutter/foundation.dart';

import '../../../core/erorrs/app_exception.dart';
import '../models/vendor_model.dart';
import '../service/vendor_service.dart';

class VendorProvider extends ChangeNotifier {
  VendorProvider(this._service);

  final VendorService _service;

  List<VendorModel> _allVendors = [];
  List<VendorModel> _vendors = [];
  Map<String, List<VendorModel>> vendorFiltered = {};
  bool _loading = false;
  String? _error;

  List<VendorModel> get vendors => _vendors;
  bool get loading => _loading;
  String? get error => _error;
  int get count => _vendors.length;

  String? _verificationStatus;
  String? _status;
  String? _type;

  bool noFilter () {
    if (_allVendors.isEmpty || _vendors.isEmpty) return true;
    return _allVendors.length == _vendors.length;
  }



  void applyFilter(String? verificationStatus, String? status, String? type) async {

    _verificationStatus = verificationStatus;
    _status = status;
    _type = type;

    await getVendors(verificationStatus, status, type, null);

  }

  void search(String searchQuery) async {
    await getVendors(_verificationStatus, _status, _type, searchQuery, refresh: true);
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    await getVendors(null, null, null, null);
  }

  Future<void> getVendors(String? verificationStatus, String? status, String? type, String? searchQuery,
      {bool refresh = false}) async {

    try {

      if (_allVendors.isNotEmpty && !refresh) {
        _vendors = _allVendors.where((v) {
          final matchStatus = status == null || v.status == status;
          final matchVerification =
              verificationStatus == null ||
                  v.verificationStatus == verificationStatus;
          final matchType = type == null || v.vendorType == type;

          return matchStatus && matchVerification && matchType;
        }).toList();

        _loading = false;
        notifyListeners();
        return;
      }


      _allVendors = await _service.getVendors(verificationStatus, status, type, searchQuery);
      _vendors = _allVendors.where((v) {
        final matchStatus = status == null || v.status == status;
        final matchVerification =
            verificationStatus == null ||
                v.verificationStatus == verificationStatus;
        final matchType = type == null || v.vendorType == type;

        return matchStatus && matchVerification && matchType;
      }).toList();
      _loading = false;
      notifyListeners();

    } on AppException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Approve a vendor. Removes it from the pending list on success.
  /// Returns an error message string, or null on success.
  Future<String?> approve(String vendorId) async {
    try {
      await _service.approveVendor(vendorId);
      _vendors.removeWhere((v) => v.id == vendorId);
      notifyListeners();
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  /// Reject a vendor with a reason. Removes it from the pending list on success.
  Future<String?> reject(String vendorId, {required String reason}) async {
    try {
      await _service.rejectVendor(vendorId, reason);
      _vendors.removeWhere((v) => v.id == vendorId);
      notifyListeners();
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }
}