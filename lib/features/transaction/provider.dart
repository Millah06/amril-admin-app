import 'package:admin_panel/features/transaction/service.dart';
import 'package:flutter/foundation.dart';

import '../../core/erorrs/app_exception.dart';
import 'model.dart';


class TransactionsProvider extends ChangeNotifier {
  TransactionsProvider(this._service);

  final TransactionsService _service;

  List<AdminTransaction> _transactions = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  double _totalVolume = 0;
  double _creditVolume = 0;
  double _debitVolume = 0;
  double _netVolume = 0;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  TxFilter _filter = TxFilter.empty;
  // Bumped on every load() call; a response is only applied if it's still
  // the most recent request — guards against an older, slower request
  // (e.g. from a filter change that got superseded) overwriting fresher data.
  int _loadRequestId = 0;

  // Search state
  AdminTransaction? _searchResult;
  bool _searching = false;
  String? _searchError;

  List<AdminTransaction> get transactions => _transactions;
  int get total => _total;
  double get totalVolume => _totalVolume;
  double get creditVolume => _creditVolume;
  double get debitVolume => _debitVolume;
  double get netVolume => _netVolume;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  TxFilter get filter => _filter;
  bool get hasNextPage => _currentPage < _totalPages;

  AdminTransaction? get searchResult => _searchResult;
  bool get searching => _searching;
  String? get searchError => _searchError;

  Future<void> load({bool silent = false}) async {
    _currentPage = 1;
    final requestId = ++_loadRequestId;
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final result = await _service.getTransactions(
        page: 1,
        status: _filter.status,
        type: _filter.type,
        userId: _filter.userId,
        from: _filter.from,
        to: _filter.to,
      );
      // A newer load() (e.g. from a filter change) started after this one —
      // discard this now-stale response instead of overwriting fresher data.
      if (requestId != _loadRequestId) return;
      _transactions = result.data;
      _totalPages = result.pages;
      _total = result.total;
      _totalVolume = result.totalVolume;
      _creditVolume = result.creditVolume;
      _debitVolume = result.debitVolume;
      _netVolume = result.netVolume;
    } on AppException catch (e) {
      if (requestId != _loadRequestId) return;
      _error = e.message;
    } finally {
      if (requestId == _loadRequestId) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !hasNextPage) return;
    _loadingMore = true;
    // Snapshot the filter + request id so a filter change that arrives
    // mid-flight can't cause this page's results to be appended under the
    // wrong filter, or a concurrent load() from overwriting them.
    final requestId = _loadRequestId;
    final filterSnapshot = _filter;
    final nextPage = _currentPage + 1;
    notifyListeners();

    try {
      final result = await _service.getTransactions(
        page: nextPage,
        status: filterSnapshot.status,
        type: filterSnapshot.type,
        userId: filterSnapshot.userId,
        from: filterSnapshot.from,
        to: filterSnapshot.to,
      );
      if (requestId != _loadRequestId) return; // filter changed mid-flight
      _currentPage = nextPage;
      _transactions.addAll(result.data);
      _totalPages = result.pages;
    } on AppException catch (_) {
      // Silent fail on pagination
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> applyFilter(TxFilter f) async {
    _filter = f;
    await load();
  }

  Future<void> clearFilter() async {
    _filter = TxFilter.empty;
    await load();
  }

  /// Search by transaction reference
  Future<void> searchByRef(String ref) async {
    if (ref.trim().isEmpty) {
      _searchResult = null;
      _searchError = null;
      notifyListeners();
      return;
    }

    _searching = true;
    _searchResult = null;
    _searchError = null;
    notifyListeners();

    try {
      _searchResult = await _service.searchByRef(ref.trim());
    } on AppException catch (e) {
      _searchError = e.message;
    } finally {
      _searching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResult = null;
    _searchError = null;
    notifyListeners();
  }

  /// Refund a transaction. Returns null on success, else the error message.
  ///
  /// The refunded row is NOT removed from the list: it still exists in the
  /// database (a separate credit row records the refund), so dropping it made a
  /// real transaction silently vanish from the admin's view. Reload instead so
  /// the list shows both the original and the new refund row.
  Future<String?> refund(String transactionId, {String? reason}) async {
    try {
      await _service.refund(transactionId, reason: reason);
      await load();
      return null; // success — return null error
    } on AppException catch (e) {
      return e.message;
    }
  }
}