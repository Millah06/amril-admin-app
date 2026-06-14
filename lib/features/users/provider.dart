import 'package:admin_panel/features/users/service.dart';
import 'package:flutter/foundation.dart';


import '../../core/erorrs/app_exception.dart';

import 'model.dart';

/// Filter state for the users list
class UserFilter {
  const UserFilter({
    this.role,
    this.active,
    this.kycStatus,
    this.search,
  });

  final String? role;
  final bool? active;
  final String? kycStatus;
  final String? search;

  bool get hasFilters => role != null || active != null || kycStatus != null || (search?.isNotEmpty == true);

  UserFilter copyWith({
    String? role,
    bool? active,
    String? kycStatus,
    String? search,
    bool clearRole = false,
    bool clearActive = false,
    bool clearKyc = false,
  }) {
    return UserFilter(
      role: clearRole ? null : (role ?? this.role),
      active: clearActive ? null : (active ?? this.active),
      kycStatus: clearKyc ? null : (kycStatus ?? this.kycStatus),
      search: search ?? this.search,
    );
  }

  static const empty = UserFilter();
}

class UsersProvider extends ChangeNotifier {
  UsersProvider(this._service);

  final UsersService _service;

  List<AdminUser> _users = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  UserFilter _filter = UserFilter.empty;

  List<AdminUser> get users => _users;
  int get total => _total;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  UserFilter get filter => _filter;
  bool get hasNextPage => _currentPage < _totalPages;

  /// Initial load / refresh
  Future<void> load({bool silent = false}) async {
    _currentPage = 1;
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final result = await _service.getUsers(
        page: 1,
        role: _filter.role,
        active: _filter.active,
        kycStatus: _filter.kycStatus,
        search: _filter.search,
      );
      _users = result.data;
      _totalPages = result.pages;
      _total = result.total;
    } on AppException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Load next page (infinite scroll)
  Future<void> loadMore() async {
    if (_loadingMore || !hasNextPage) return;
    _loadingMore = true;
    notifyListeners();

    try {
      final result = await _service.getUsers(
        page: _currentPage + 1,
        role: _filter.role,
        active: _filter.active,
        kycStatus: _filter.kycStatus,
        search: _filter.search,
      );
      _currentPage++;
      _users.addAll(result.data);
      _totalPages = result.pages;
    } on AppException catch (_) {
      // Silently fail on pagination errors
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// Apply new filters and reload
  Future<void> applyFilter(UserFilter f) async {
    _filter = f;
    await load();
  }

  /// Clear all filters
  Future<void> clearFilter() async {
    _filter = UserFilter.empty;
    await load();
  }

  /// Block or unblock a user — optimistically updates local state
  Future<String?> setUserActiveStatus({
    required String userId,
    required bool active,
    String? reason,
  }) async {
    try {
      await _service.setUserActiveStatus(
        userId: userId,
        active: active,
        reason: reason,
      );
      final idx = _users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        _users[idx] = AdminUser(
          id: _users[idx].id,
          name: _users[idx].name,
          email: _users[idx].email,
          phone: _users[idx].phone,
          role: _users[idx].role,
          active: active,
          transferUid: _users[idx].transferUid,
          createdAt: _users[idx].createdAt,
          kycStatus: _users[idx].kycStatus,
          avatarUrl: _users[idx].avatarUrl,
          isVerified: _users[idx].isVerified,
          availableBalance: _users[idx].availableBalance,
          lockedBalance: _users[idx].lockedBalance,
        );
        notifyListeners();
      }
      return null; // no error
    } on AppException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateRole({required String userId, required String role}) async {
    try {
      await _service.updateRole(userId: userId, role: role);
      await load(silent: true);
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateKyc({
    required String userId,
    required String status,
    String? reason,
  }) async {
    try {
      await _service.updateKyc(userId: userId, status: status, reason: reason);
      await load(silent: true);
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }
}