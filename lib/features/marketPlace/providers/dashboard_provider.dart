import 'package:flutter/foundation.dart';
import '../../../core/erorrs/app_exception.dart';
import '../service/dashboard_services.dart';


class MarketDashboardProvider extends ChangeNotifier {
  MarketDashboardProvider(this._service);

  final MarketDashboardService _service;

  MarketDashboardStats? _stats;
  bool _loading = false;
  String? _error;

  MarketDashboardStats? get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _stats = await _service.getStats();
    } on AppException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}