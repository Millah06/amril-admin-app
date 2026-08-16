import 'package:flutter/foundation.dart';
import 'model.dart';
import 'service.dart';

class PartnerProvider extends ChangeNotifier {
  PartnerProvider(this._service);

  final PartnerService _service;

  // ── List state ─────────────────────────────────────────────────────────────
  List<PartnerLite> partners = [];
  bool loading = false;
  String? error;
  String? _search;

  // ── Detail state ────────────────────────────────────────────────────────────
  PartnerDetail? detail;
  bool loadingDetail = false;

  // ── Commission calculator state ────────────────────────────────────────────
  CommissionSummary? commissionSummary;
  bool calculatingCommission = false;

  // ── Payout state ───────────────────────────────────────────────────────────
  bool savingPayout = false;

  Future<void> loadPartners({bool silent = false, String? search}) async {
    _search = search;
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      partners = await _service.getPartners(search: _search);
      error = null;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadDetail(String partnerId) async {
    loadingDetail = true;
    error = null;
    notifyListeners();
    try {
      detail = await _service.getPartner(partnerId);
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      loadingDetail = false;
      notifyListeners();
    }
  }

  Future<bool> createPartner({
    required String name,
    String phone = '',
    String email = '',
    String tier = 'PARTNER',
    double commissionRate = 1,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _service.createPartner(
        name: name,
        phone: phone,
        email: email,
        tier: tier,
        commissionRate: commissionRate,
      );
      await loadPartners(silent: true);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePartner(
    String partnerId, {
    String? name,
    String? phone,
    String? email,
    String? tier,
    String? status,
    double? commissionRate,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _service.updatePartner(
        partnerId,
        name: name,
        phone: phone,
        email: email,
        tier: tier,
        status: status,
        commissionRate: commissionRate,
      );
      // Refresh detail if open
      if (detail?.id == partnerId) await loadDetail(partnerId);
      await loadPartners(silent: true);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignVendor(String partnerId, String vendorId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _service.assignVendor(partnerId, vendorId);
      await loadDetail(partnerId);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeVendorAssignment(
      String partnerId, String linkId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _service.removeVendorAssignment(partnerId, linkId);
      await loadDetail(partnerId);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> linkUser(String partnerId, String userId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _service.linkUserToPartner(partnerId, userId);
      await loadDetail(partnerId);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> calculateCommission(
      String partnerId, int month, int year) async {
    calculatingCommission = true;
    commissionSummary = null;
    error = null;
    notifyListeners();
    try {
      commissionSummary =
          await _service.calculateCommission(partnerId, month, year);
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      calculatingCommission = false;
      notifyListeners();
    }
  }

  Future<bool> createPayout({
    required String partnerId,
    required int month,
    required int year,
    required double transactionAmount,
    required double commissionRate,
    required double commissionAmount,
    String? note,
  }) async {
    savingPayout = true;
    error = null;
    notifyListeners();
    try {
      await _service.createPayout(
        partnerId: partnerId,
        month: month,
        year: year,
        transactionAmount: transactionAmount,
        commissionRate: commissionRate,
        commissionAmount: commissionAmount,
        note: note,
      );
      await loadDetail(partnerId);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      savingPayout = false;
      notifyListeners();
      return false;
    } finally {
      savingPayout = false;
      notifyListeners();
    }
  }

  Future<bool> markPayoutPaid(
      String partnerId, String payoutId, {String? note}) async {
    savingPayout = true;
    error = null;
    notifyListeners();
    try {
      await _service.updatePayout(
        partnerId: partnerId,
        payoutId: payoutId,
        status: 'PAID',
        note: note,
      );
      await loadDetail(partnerId);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      savingPayout = false;
      notifyListeners();
      return false;
    } finally {
      savingPayout = false;
      notifyListeners();
    }
  }

  Future<bool> cancelPayout(String partnerId, String payoutId) async {
    savingPayout = true;
    error = null;
    notifyListeners();
    try {
      await _service.updatePayout(
        partnerId: partnerId,
        payoutId: payoutId,
        status: 'CANCELLED',
      );
      await loadDetail(partnerId);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      savingPayout = false;
      notifyListeners();
      return false;
    } finally {
      savingPayout = false;
      notifyListeners();
    }
  }
}
