// REPO PATH: lib/features/reconciliation/provider.dart   (NEW FILE — admin_panel)
//
// ChangeNotifier following the admin app's provider convention (loading / error
// / data + load({silent})). Holds the admin-entered OPay/Apple/Google balances
// so a "recompute" and a "save snapshot" use the same inputs.

import 'package:flutter/foundation.dart';

import 'model.dart';
import 'service.dart';

class TreasuryProvider extends ChangeNotifier {
  final TreasuryService _service;
  TreasuryProvider(this._service);

  bool loading = false;
  String? error;
  TreasurySummary? summary;

  // Admin-entered, externally-known balances (Paystack + Monnify are auto-
  // fetched server side; monnify here is an OVERRIDE for before creds are set).
  // Null = "not entered" → backend treats as 0 / auto-fetch for that input.
  double? opay;
  double? monnify; // override — skips the live Monnify fetch when entered
  double? bank;    // operating/settlement bank where PSPs settle
  double? vtpass;  // VTPass prepaid wallet
  double? apple;
  double? google;

  bool saving = false;
  String? saveMessage; // transient toast text after a save attempt

  /// Recompute live figures using the current manual inputs.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      summary = await _service.getSummary(
        opay: opay,
        monnify: monnify,
        bank: bank,
        vtpass: vtpass,
        apple: apple,
        google: google,
      );
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Persist a snapshot with the current manual inputs.
  Future<void> saveSnapshot({String? note}) async {
    saving = true;
    saveMessage = null;
    notifyListeners();
    try {
      summary = await _service.takeSnapshot(
        opay: opay,
        monnify: monnify,
        bank: bank,
        vtpass: vtpass,
        apple: apple,
        google: google,
        note: note,
      );
      saveMessage = 'Snapshot saved';
    } catch (e) {
      saveMessage = 'Save failed: $e';
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  void setOpay(String v) => opay = double.tryParse(v.trim());
  void setMonnify(String v) => monnify = double.tryParse(v.trim());
  void setBank(String v) => bank = double.tryParse(v.trim());
  void setVtpass(String v) => vtpass = double.tryParse(v.trim());
  void setApple(String v) => apple = double.tryParse(v.trim());
  void setGoogle(String v) => google = double.tryParse(v.trim());
}