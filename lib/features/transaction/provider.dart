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
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  TxFilter _filter = TxFilter.empty;

  // Search state
  AdminTransaction? _searchResult;
  bool _searching = false;
  String? _searchError;

  List<AdminTransaction> get transactions => _transactions;
  int get total => _total;
  double get totalVolume => _totalVolume;
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
      _transactions = result.data;
      _totalPages = result.pages;
      _total = result.total;
      _totalVolume = result.totalVolume;
    } on AppException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !hasNextPage) return;
    _loadingMore = true;
    notifyListeners();

    try {
      final result = await _service.getTransactions(
        page: _currentPage + 1,
        status: _filter.status,
        type: _filter.type,
        userId: _filter.userId,
        from: _filter.from,
        to: _filter.to,
      );
      _currentPage++;
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

  /// Refund a transaction — removes it from list on success
  Future<String?> refund(String transactionId, {String? reason}) async {
    try {
      final ref = await _service.refund(transactionId, reason: reason);
      // Optimistically remove from list
      _transactions.removeWhere((t) => t.id == transactionId);
      notifyListeners();
      return null; // success — return null error
    } on AppException catch (e) {
      return e.message;
    }
  }
}