import 'package:admin_panel/features/users/provider.dart';
import 'package:admin_panel/features/users/user_filter_sheet.dart';
import 'package:admin_panel/features/users/user_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_list.dart';

import 'user_detail_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().load();
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<UsersProvider>().loadMore();
    }
  }

  void _onSearch(String query) {
    final provider = context.read<UsersProvider>();
    provider.applyFilter(provider.filter.copyWith(search: query));
  }

  Future<void> _openFilter() async {
    final provider = context.read<UsersProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UserFilterSheet(
        current: provider.filter,
        onApply: (f) => provider.applyFilter(f),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<UsersProvider>(
          builder: (_, p, __) => Text('Users (${p.total})'),
        ),
        actions: [
          Consumer<UsersProvider>(
            builder: (_, p, __) => IconButton(
              icon: Badge(
                isLabelVisible: p.filter.hasFilters,
                child: const Icon(Icons.tune_rounded),
              ),
              tooltip: 'Filter',
              onPressed: _openFilter,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or UID…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: ValueListenableBuilder(
                  valueListenable: _searchCtrl,
                  builder: (_, v, __) => v.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onSearch('');
                    },
                  )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // ── Active filter chips ────────────────────────────────────────
          Consumer<UsersProvider>(
            builder: (_, p, __) {
              if (!p.filter.hasFilters) return const SizedBox.shrink();
              return _ActiveFilters(filter: p.filter, onClear: p.clearFilter);
            },
          ),

          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: Consumer<UsersProvider>(
              builder: (_, provider, __) {
                if (provider.loading) return const LoadingList();
                if (provider.error != null) {
                  return ErrorView(
                    message: provider.error!,
                    onRetry: () => provider.load(),
                  );
                }
                if (provider.users.isEmpty) {
                  return const _EmptyUsers();
                }

                return RefreshIndicator(
                  onRefresh: () => provider.load(silent: true),
                  child: ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: provider.users.length + (provider.loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      if (i == provider.users.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final user = provider.users[i];
                      return UserListTile(
                        user: user,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserDetailScreen(userId: user.id),
                          ),
                        ).then((_) => provider.load(silent: true)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active filter chips row ────────────────────────────────────────────────────

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.filter, required this.onClear});

  final UserFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (filter.role != null) _Chip(label: 'Role: ${filter.role}'),
          if (filter.active != null)
            _Chip(label: filter.active! ? 'Active' : 'Blocked'),
          if (filter.kycStatus != null)
            _Chip(label: 'KYC: ${filter.kycStatus}'),
          ActionChip(
            label: const Text('Clear', style: TextStyle(fontSize: 12)),
            avatar: const Icon(Icons.close_rounded, size: 14),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        backgroundColor: AppTheme.accent.withOpacity(0.08),
        side: BorderSide(color: AppTheme.accent.withOpacity(0.3)),
      ),
    );
  }
}

class _EmptyUsers extends StatelessWidget {
  const _EmptyUsers();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 48, color: AppTheme.textSecondary),
          SizedBox(height: 12),
          Text(
            'No users found',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}