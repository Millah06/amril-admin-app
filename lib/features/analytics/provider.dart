import 'package:admin_panel/features/analytics/service.dart';
import 'package:flutter/foundation.dart';

import '../../core/erorrs/app_exception.dart';
import 'model.dart';

enum AnalyticsPeriod { all, week, month }

extension AnalyticsPeriodExt on AnalyticsPeriod {
  String get apiValue {
    switch (this) {
      case AnalyticsPeriod.week:
        return '7d';
      case AnalyticsPeriod.month:
        return '30d';
      case AnalyticsPeriod.all:
        return 'all';
    }
  }

  String get label {
    switch (this) {
      case AnalyticsPeriod.week:
        return 'Last 7 days';
      case AnalyticsPeriod.month:
        return 'Last 30 days';
      case AnalyticsPeriod.all:
        return 'All time';
    }
  }
}

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider(this._service);

  final AnalyticsService _service;

  List<TopUserByVolume> _topByVolume = [];
  List<TopUserByBalance> _topByBalance = [];
  BalanceSummary? _balanceSummary;
  bool _loading = false;
  String? _error;
  AnalyticsPeriod _period = AnalyticsPeriod.all;
  String? _volumeType; // null = all, 'credit', 'debit'

  List<TopUserByVolume> get topByVolume => _topByVolume;
  List<TopUserByBalance> get topByBalance => _topByBalance;
  BalanceSummary? get balanceSummary => _balanceSummary;
  bool get loading => _loading;
  String? get error => _error;
  AnalyticsPeriod get period => _period;
  String? get volumeType => _volumeType;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      // Run all three requests in parallel for speed.
      // Each future is typed independently to avoid unsafe casts.
      final topVolumeFuture = _service.getTopUsersByVolume(
        period: _period.apiValue,
        type: _volumeType,
      );
      final topBalanceFuture = _service.getTopUsersByBalance();
      final summaryFuture = _service.getBalanceSummary();

      _topByVolume = await topVolumeFuture;
      _topByBalance = await topBalanceFuture;
      _balanceSummary = await summaryFuture;
    } on AppException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setPeriod(AnalyticsPeriod p) async {
    _period = p;
    await load(silent: true);
  }

  Future<void> setVolumeType(String? type) async {
    _volumeType = type;
    await load(silent: true);
  }
}