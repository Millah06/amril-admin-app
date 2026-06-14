import 'package:admin_panel/features/transaction/provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_list.dart';

import 'list_tile.dart';
import 'model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  late final TabController _tabCtrl;

  // Tabs map to status filters
  static const _tabs = ['All', 'Success', 'Pending', 'Failed'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
    _scrollCtrl.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabCtrl.indexIsChanging) return;
    final status = _tabs[_tabCtrl.index].toLowerCase();
    final p = context.read<TransactionsProvider>();
    p.applyFilter(
      p.filter.copyWith(
        clearStatus: true,
        status: status == 'all' ? null : status,
      ),
    );
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<TransactionsProvider>().loadMore();
    }
  }

  void _onSearchSubmit(String ref) {
    context.read<TransactionsProvider>().searchByRef(ref);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    context.read<TransactionsProvider>().clearSearch();
  }

  Future<void> _onRefund(AdminTransaction tx) async {
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Refund ${AppFormatters.naira(tx.amount)} to ${tx.userName ?? 'this user'}?',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g. Duplicate charge',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Refund'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final err = await context.read<TransactionsProvider>().refund(
      tx.id,
      reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Refund processed successfully'),
        backgroundColor: err != null ? AppTheme.danger : AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TransactionsProvider>(),
        child: const _TxFilterSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          Consumer<TransactionsProvider>(
            builder: (_, p, __) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: _openFilters,
                ),
                if (p.filter.hasFilters)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.accent,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      body: Column(
        children: [
          // ── Search by ref ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearchSubmit,
              decoration: InputDecoration(
                hintText: 'Search by transaction reference…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _clearSearch,
                )
                    : null,
              ),
            ),
          ),

          // ── Volume summary ──────────────────────────────────────────────
          Consumer<TransactionsProvider>(
            builder: (_, p, __) {
              if (p.loading || p.total == 0) return const SizedBox(height: 8);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Text(
                      '${p.total} transactions',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Vol: ${AppFormatters.naira(p.totalVolume)}',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: Consumer<TransactionsProvider>(
              builder: (_, provider, __) {
                // Show search result if active
                if (provider.searching) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.searchResult != null) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 14, color: AppTheme.accent),
                            const SizedBox(width: 8),
                            const Text(
                              'Search result',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _clearSearch,
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: AppTheme.accent, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TransactionListTile(
                          tx: provider.searchResult!,
                          onRefund: provider.searchResult!.canBeRefunded
                              ? () => _onRefund(provider.searchResult!)
                              : null,
                        ),
                      ),
                    ],
                  );
                }

                if (provider.searchError != null) {
                  return Center(
                    child: Text(
                      provider.searchError!,
                      style: const TextStyle(color: AppTheme.danger),
                    ),
                  );
                }

                if (provider.loading) return const LoadingList();

                if (provider.error != null) {
                  return ErrorView(
                    message: provider.error!,
                    onRetry: () => provider.load(),
                  );
                }

                if (provider.transactions.isEmpty) {
                  return const EmptyView(
                    icon: Icons.receipt_long_outlined,
                    message: 'No transactions found',
                    subtitle: 'Try adjusting your filters',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.load(silent: true),
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: provider.transactions.length + (provider.loadingMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == provider.transactions.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final tx = provider.transactions[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TransactionListTile(
                          tx: tx,
                          onRefund: tx.canBeRefunded ? () => _onRefund(tx) : null,
                        ),
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

// ── Transaction Filter Sheet ──────────────────────────────────────────────────

class _TxFilterSheet extends StatefulWidget {
  const _TxFilterSheet();

  @override
  State<_TxFilterSheet> createState() => _TxFilterSheetState();
}

class _TxFilterSheetState extends State<_TxFilterSheet> {
  String? _type;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    final f = context.read<TransactionsProvider>().filter;
    _type = f.type;
    _from = f.from;
    _to = f.to;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  void _apply() {
    final p = context.read<TransactionsProvider>();
    final clearDates = _from == null && _to == null;
    p.applyFilter(
      p.filter.copyWith(
        clearType: true,
        clearDate: clearDates,
        type: _type,
        from: _from,
        to: _to,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Filter Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 20),
          const _FilterLabel('Type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['credit', 'debit'].map((t) {
              final sel = _type == t;
              return ChoiceChip(
                label: Text(t),
                selected: sel,
                onSelected: (_) => setState(() => _type = sel ? null : t),
                selectedColor: AppTheme.accent.withOpacity(0.12),
                labelStyle: TextStyle(
                  color: sel ? AppTheme.accent : AppTheme.textPrimary,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const _FilterLabel('Date Range'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: _from == null ? 'From date' : AppFormatters.date(_from!),
                  onTap: () => _pickDate(isFrom: true),
                  hasValue: _from != null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateButton(
                  label: _to == null ? 'To date' : AppFormatters.date(_to!),
                  onTap: () => _pickDate(isFrom: false),
                  hasValue: _to != null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _type = null;
                    _from = null;
                    _to = null;
                  }),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(onPressed: _apply, child: const Text('Apply')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppTheme.textSecondary,
      letterSpacing: 0.5,
    ),
  );
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.label, required this.onTap, required this.hasValue});
  final String label;
  final VoidCallback onTap;
  final bool hasValue;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: hasValue ? AppTheme.accent.withOpacity(0.06) : AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasValue ? AppTheme.accent.withOpacity(0.4) : AppTheme.divider,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 14,
              color: hasValue ? AppTheme.accent : AppTheme.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: hasValue ? AppTheme.accent : AppTheme.textSecondary,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}