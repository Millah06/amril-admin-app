import 'package:flutter/foundation.dart';

import '../../../core/erorrs/app_exception.dart';
import '../models/appeal_model.dart';
import '../service/appeal_service.dart';

class AppealProvider extends ChangeNotifier {
  AppealProvider(this._service);

  final AppealService _service;

  List<AppealOrder> _appeals = [];
  bool _loading = false;
  String? _error;
  // Tracks which orderId is currently being resolved (shows spinner on that row)
  String? _resolvingId;
  // Tracks which orderId is having a chat message sent
  bool _sendingMessage = false;

  List<AppealOrder> get appeals => _appeals;
  bool get loading => _loading;
  String? get error => _error;
  String? get resolvingId => _resolvingId;
  bool get sendingMessage => _sendingMessage;
  int get count => _appeals.length;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _appeals = await _service.getAppeals();
    } on AppException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Resolve an appeal.
  /// [decision]: 'release_vendor' or 'refund_user'
  /// Returns error message or null on success.
  Future<String?> resolve({
    required String orderId,
    required String decision,
    String? reason,
  }) async {
    _resolvingId = orderId;
    notifyListeners();

    try {
      await _service.resolveAppeal(
        orderId: orderId,
        decision: decision,
        reason: reason,
      );
      // Remove from list — it's resolved
      _appeals.removeWhere((a) => a.id == orderId);
      return null;
    } on AppException catch (e) {
      return e.message;
    } finally {
      _resolvingId = null;
      notifyListeners();
    }
  }

  /// Send an admin chat message for a specific order.
  Future<String?> sendMessage({
    required String orderId,
    required String message,
  }) async {
    _sendingMessage = true;
    notifyListeners();

    try {
      await _service.sendChatMessage(orderId: orderId, message: message);
      return null;
    } on AppException catch (e) {
      return e.message;
    } finally {
      _sendingMessage = false;
      notifyListeners();
    }
  }

}