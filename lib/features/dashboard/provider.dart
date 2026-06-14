import 'package:admin_panel/features/dashboard/service.dart';
import 'package:flutter/foundation.dart';
import '../../core/erorrs/app_exception.dart';
import 'model.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._service);

  final DashboardService _service;

  DashboardStats? _stats;
  bool _loading = false;
  String? _error;

  DashboardStats? get stats => _stats;
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