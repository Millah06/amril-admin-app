import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_list.dart';
import '../models/vendor_model.dart';
import '../providers/vendor_provider.dart';
import '../screens/appeal_detail_screen.dart';
import '../screens/vendor_detail_screen.dart';
import '../screens/vendor_filter_sheet.dart';

class VendorsTab extends StatefulWidget {
  const VendorsTab({super.key});

  @override
  State<VendorsTab> createState() => _VendorsTabState();
}

class _VendorsTabState extends State<VendorsTab> {

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorProvider>().load();
    });
  }

  Future<void> _approve(VendorModel vendor) async {
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

  Future<void> _reject(VendorModel vendor) async {
    // Ask for a reason before confirming
    final reason = await _askReason(vendor.name);
    if (reason == null || !mounted) return;

    final err = await context
        .read<VendorProvider>()
        .reject(vendor.id, reason: reason);
    if (!mounted) return;
    _showSnack(err ?? '${vendor.name} rejected', isError: err != null);
  }

  Future<String?> _askReason(String vendorName) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reject $vendorName'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
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
            child: const Text('Reject'),
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
    final provider = context.read<VendorProvider>();
    provider.search(query);
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
          child: VendorFilterSheet()
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<VendorProvider>(
          builder: (_, p, __) => Text(
              'Pending Vendors${p.count > 0 ? ' (${p.count})' : ''}'),
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
          // ── Search bar ────────────────────────────────────────────────
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
                if (provider.error != null) {
                  return ErrorView(
                    message: provider.error!,
                    onRetry: () => provider.load(),
                  );
                }
                if (provider.vendors.isEmpty) {
                  return const EmptyView(
                    icon: Icons.store_outlined,
                    message: 'No pending vendors',
                    subtitle: 'All applications have been reviewed',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.load(silent: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: provider.vendors.length,
                    itemBuilder: (_, i) {
                      final v = provider.vendors[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _VendorCard(
                          vendor: v,
                          onViewDetail: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VendorDetailScreen(vendor: v),
                            ),
                          ),
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
      )
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

  final VendorModel vendor;
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
              // ── Header ─────────────────────────────────────────────
              Row(
                children: [
                  // Logo / icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.08),
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
                            _TypeChip(type: vendor.vendorType),
                            const SizedBox(width: 6),
                            Text(
                              AppFormatters.timeAgo(vendor.createdAt),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary),
                            ),
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

              // ── Description snippet ────────────────────────────────
              if (vendor.description.isNotEmpty)
                Text(
                  vendor.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              const SizedBox(height: 4),

              // ── Contact row ────────────────────────────────────────
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
                  ],
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Action buttons ─────────────────────────────────────
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
          ),
        ),
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
      color: AppTheme.accent.withOpacity(0.08),
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