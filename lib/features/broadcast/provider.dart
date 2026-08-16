import 'package:flutter/foundation.dart';

import '../../core/erorrs/app_exception.dart';
import 'service.dart';

enum BroadcastState { idle, sending, success, error }

class BroadcastProvider extends ChangeNotifier {
  BroadcastProvider(this._service);

  final BroadcastService _service;

  BroadcastState _state = BroadcastState.idle;
  String? _error;
  String? _lastFcmId;

  BroadcastState get state => _state;
  String? get error => _error;
  String? get lastFcmId => _lastFcmId;
  bool get sending => _state == BroadcastState.sending;

  Future<bool> send({
    required String message,
    String? title,
    String? imageUrl,
    String? route,
  }) async {
    _state = BroadcastState.sending;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.send(
        message: message,
        title: title,
        imageUrl: imageUrl,
        route: route,
      );
      _lastFcmId = result['fcmMessageId'] as String?;
      _state = BroadcastState.success;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _state = BroadcastState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _state = BroadcastState.error;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _state = BroadcastState.idle;
    _error = null;
    notifyListeners();
  }
}
