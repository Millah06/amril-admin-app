import 'package:admin_panel/features/marketPlace/marketPlacePush.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_list.dart';
import '../models/vendor_model.dart';
import '../providers/vendor_provider.dart';
import '../screens/vendor_detail_screen.dart';
import '../screens/vendor_filter_sheet.dart';

class VendorsTab extends StatefulWidget {
  const VendorsTab({super.key});

  @override
  State<VendorsTab> createState() => _VendorsTabState();
}

class _VendorsTabState extends State<VendorsTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  /// Quick-chip label → server `?status=`. The SELECTED chip is derived from
  /// the provider's current status filter so a status picked in the filter
  /// sheet highlights the same chip (single source of truth).
  static const _statusChips = <String, String?>{
    'All': null,
    'Pending': 'pending',
    'Approved': 'approved',
    'Suspended': 'suspended',
    'Rejected': 'rejected',
  };

  String _chipLabelFor(String? status) => _statusChips.entries
      .firstWhere((e) => e.value == status,
          orElse: () => _statusChips.entries.first)
      .key;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorProvider>().setStatusFilter('pending');
    });
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      context.read<VendorProvider>().loadMore();
    }
  }

  Future<void> _approve(VendorLite vendor) async {
    final confirmed = await _confirm(
      'Approve ${vendor.name}?',
      'The vendor will be notified and their store will become visible.',
      confirmLabel: 'Approve',
    );
    if (!confirmed || !mounted) return;

    final err = await context.read<VendorProvider>().approve(vendor.id);
    if (!mounted) return;
    _showSnack(err ?? '${vendor.name} approved ✓', isError: err != null);
  }

  Future<void> _reject(VendorLite vendor) async {
    final reason = await _askReason(vendor.name);
    if (reason == null || !mounted) return;

    final err = await context
        .read<VendorProvider>()
        .reject(vendor.id, reason: reason);
    if (!mounted) return;
    _showSnack(err ?? '${vendor.name} rejected', isError: err != null);
  }

  Future<String?> _askReason(String vendorName,
      {String title = 'Reject Vendor'}) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$title $vendorName'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'e.g. Incomplete documents',
          ),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(
                context,
                ctrl.text.trim().isEmpty
                    ? 'Application did not meet our requirements'
                    : ctrl.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(String title, String body,
      {required String confirmLabel}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body,
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _onSearch(String query) {
    context.read<VendorProvider>().search(query);
  }

  void _openFilter() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => ChangeNotifierProvider.value(
            value: context.read<VendorProvider>(),
            child: const VendorFilterSheet()));
  }

  Future<void> _openDetail(VendorLite v) async {
    final changed = await marketPush<bool>(
        context, VendorDetailScreen(vendorId: v.id, lite: v));
    if (changed == true && mounted) {
      context.read<VendorProvider>().load(silent: true);
    }
  }

  void _setFilter(String filter) {
    context.read<VendorProvider>().setStatusFilter(_statusChips[filter]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<VendorProvider>(
          builder: (_, p, __) => Text(
              '${_chipLabelFor(p.statusFilter)} Vendors${p.count > 0 ? ' (${p.count}${p.hasMore ? '+' : ''})' : ''}'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<VendorProvider>().load(),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: !context.watch<VendorProvider>().noFilter(),
              child: const Icon(Icons.tune_rounded),
            ),
            tooltip: 'Filter',
            onPressed: _openFilter,
          )
        ],
      ),
      body: Column(
        children: [
          // ── Filter buttons ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Consumer<VendorProvider>(
                builder: (_, p, __) {
                  final selectedLabel = _chipLabelFor(p.statusFilter);
                  return Row(
                    children: _statusChips.keys
                        .map((filter) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(filter),
                                selected: selectedLabel == filter,
                                onSelected: (_) => _setFilter(filter),
                                selectedColor:
                                    AppTheme.primary.withValues(alpha: 0.2),
                                checkmarkColor: AppTheme.primary,
                                labelStyle: TextStyle(
                                  color: selectedLabel == filter
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                  fontWeight: selectedLabel == filter
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ),
          ),

          // ── Search bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone…',
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
          Expanded(
            child: Consumer<VendorProvider>(
              builder: (_, provider, __) {
                if (provider.loading) return const LoadingList();
                if (provider.error != null && provider.vendors.isEmpty) {
                  return ErrorView(
                    message: provider.error!,
                    onRetry: () => provider.load(),
                  );
                }
                if (provider.vendors.isEmpty) {
                  return EmptyView(
                    icon: Icons.store_outlined,
                    message: provider.statusFilter == null
                        ? 'No vendors yet'
                        : 'No ${_chipLabelFor(provider.statusFilter).toLowerCase()} vendors',
                    subtitle: 'No vendors match the selected filter',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.load(silent: true),
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: provider.vendors.length +
                        (provider.hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= provider.vendors.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppTheme.primary),
                            ),
                          ),
                        );
                      }
                      final v = provider.vendors[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _VendorCard(
                          vendor: v,
                          onViewDetail: () => _openDetail(v),
                          onApprove: () => _approve(v),
                          onReject: () => _reject(v),
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

// ── Vendor Card ───────────────────────────────────────────────────────────────

class _VendorCard extends StatelessWidget {
  const _VendorCard({
    required this.vendor,
    required this.onViewDetail,
    required this.onApprove,
    required this.onReject,
  });

  final VendorLite vendor;
  final VoidCallback onViewDetail;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onViewDetail,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Row(
                children: [
                  // Logo / icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: vendor.logo.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(vendor.logo,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.store, color: AppTheme.accent)))
                        : const Icon(Icons.store, color: AppTheme.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _StatusChip(status: vendor.status),
                            const SizedBox(width: 6),
                            _TypeChip(type: vendor.vendorType),
                            if (vendor.createdAt != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                AppFormatters.timeAgo(vendor.createdAt!),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppTheme.textSecondary),
                ],
              ),
              const SizedBox(height: 10),

              // ── Suspension reason snippet ────────────────────────────────
              if (vendor.isSuspended &&
                  (vendor.suspensionReason?.isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    vendor.suspensionReason!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.danger),
                  ),
                ),

              // ── Contact row ─────────────────────────────────────────────
              Row(
                children: [
                  if (vendor.email.isNotEmpty) ...[
                    const Icon(Icons.email_outlined,
                        size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        vendor.email,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (vendor.cac.isNotEmpty) ...[
                    const Icon(Icons.badge_outlined,
                        size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'CAC: ${vendor.cac}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (vendor.branchCount > 0) ...[
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${vendor.branchCount} branch${vendor.branchCount == 1 ? '' : 'es'}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              if (vendor.status == 'pending') ...[
                const Divider(height: 1),
                const SizedBox(height: 12),
                // ── Action buttons ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.danger,
                          side: const BorderSide(color: AppTheme.danger),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = vendorStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          type.toUpperCase(),
          style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5),
        ),
      );
}
