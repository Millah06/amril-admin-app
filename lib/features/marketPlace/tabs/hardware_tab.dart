import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/loading_list.dart';
import '../marketPlacePush.dart';
import '../models/hardware_model.dart';
import '../providers/hardware_provider.dart';
import '../screens/hardware/hardware_batch_edit_screen.dart';
import '../screens/hardware/hardware_batch_orders_screen.dart';
import '../screens/hardware/hardware_product_edit_screen.dart';
import '../screens/vendor_detail_screen.dart';

/// Hardware admin hub (§2). Three sections — Products, Batches, Orders — reached
/// from a segmented switch. Create/edit open DEDICATED screens (no dialogs);
/// delete is a confirm dialog; the orders board is cursor-paginated and each
/// row's vendor is tappable → VendorDetailScreen.
class HardwareTab extends StatefulWidget {
  const HardwareTab({super.key});

  @override
  State<HardwareTab> createState() => _HardwareTabState();
}

class _HardwareTabState extends State<HardwareTab> {
  int _section = 0; // 0 products, 1 batches, 2 orders
  final _ordersScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<HardwareProvider>().loadAll());
    _ordersScroll.addListener(_maybeLoadMoreOrders);
  }

  @override
  void dispose() {
    _ordersScroll.dispose();
    super.dispose();
  }

  void _maybeLoadMoreOrders() {
    if (_ordersScroll.position.pixels >=
        _ordersScroll.position.maxScrollExtent - 300) {
      context.read<HardwareProvider>().loadMoreOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hardware'),
        actions: [
          Consumer<HardwareProvider>(
            builder: (_, p, __) => IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: p.loading ? null : p.loadAll,
            ),
          ),
        ],
      ),
      floatingActionButton: _section == 2
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              onPressed: () =>
                  _section == 0 ? _openProduct(null) : _openBatch(null),
              icon: const Icon(Icons.add),
              label: Text(_section == 0 ? 'Add Product' : 'Add Batch'),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SegmentedButton<int>(
              style: SegmentedButton.styleFrom(
                backgroundColor: AppTheme.surface,
                selectedBackgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                selectedForegroundColor: AppTheme.primary,
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.divider),
              ),
              segments: const [
                ButtonSegment(value: 0, label: Text('Products')),
                ButtonSegment(value: 1, label: Text('Batches')),
                ButtonSegment(value: 2, label: Text('Orders')),
              ],
              selected: {_section},
              onSelectionChanged: (s) => setState(() => _section = s.first),
            ),
          ),
          Expanded(
            child: Consumer<HardwareProvider>(
              builder: (_, p, __) {
                if (p.loading) return const LoadingList();
                if (p.error != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p.error!,
                            style: const TextStyle(
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                            onPressed: p.loadAll, child: const Text('Retry')),
                      ],
                    ),
                  );
                }
                switch (_section) {
                  case 0:
                    return _productsList(p);
                  case 1:
                    return _batchesList(p);
                  default:
                    return _ordersList(p);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation to dedicated screens ──
  Future<void> _openProduct(HwProduct? pr) async {
    await marketPush(
      context, HardwareProductEditScreen(product: pr)
    );
  }

  Future<void> _openBatch(HwBatch? b) async {
    await marketPush(
      context, HardwareBatchEditScreen(batch: b)
    );
  }

  // ── Products ───────────────────────────────────────────────────────────────
  Widget _productsList(HardwareProvider p) {
    if (p.products.isEmpty) {
      return const EmptyView(
        icon: Icons.inventory_2_outlined,
        message: 'No products yet',
        subtitle: 'Add your first hardware product',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: p.products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final pr = p.products[i];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            onTap: () => _openProduct(pr),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 52,
                height: 52,
                child: pr.images.isNotEmpty
                    ? Image.network(pr.images.first, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbFallback(pr))
                    : _thumbFallback(pr),
              ),
            ),
            title: Text(pr.name,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatusChip(
                    label: pr.tier.toUpperCase(),
                    color: pr.isPremium ? AppTheme.primary : AppTheme.accent,
                  ),
                  _StatusChip(
                    label: pr.isAddon ? 'ADD-ON' : 'BUNDLE',
                    color: pr.isAddon ? AppTheme.warning : AppTheme.textSecondary,
                  ),
                  Text('₦${pr.priceNaira}',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600)),
                  _StatusChip(
                    label: pr.isActive ? 'Active' : 'Hidden',
                    color: pr.isActive ? AppTheme.success : AppTheme.warning,
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
                  onPressed: () => _openProduct(pr),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.danger),
                  onPressed: () => _deleteProduct(pr),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _thumbFallback(HwProduct pr) => Container(
        color: AppTheme.accent.withValues(alpha: 0.12),
        child: Icon(
          pr.isActive ? Icons.phone_android_rounded : Icons.visibility_off,
          color: pr.isActive ? AppTheme.accent : AppTheme.textSecondary,
        ),
      );

  Future<void> _deleteProduct(HwProduct pr) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete product?'),
        content: Text(
            'Delete "${pr.name}"? If it has orders it will be hidden instead.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final err = await context.read<HardwareProvider>().deleteProduct(pr.id);
    _toast(err ?? 'Deleted', isError: err != null);
  }

  // ── Batches ──────────────────────────────────────────────────────────────
  Widget _batchesList(HardwareProvider p) {
    if (p.batches.isEmpty) {
      return const EmptyView(
        icon: Icons.list_alt_outlined,
        message: 'No batches yet',
        subtitle: 'Create your first hardware batch',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: p.batches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final b = p.batches[i];
        final pct = b.progress;
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openBatch(b),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              _batchStateColor(b.state).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.inventory_outlined,
                            color: _batchStateColor(b.state)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Per-product batch title (§3); legacy tier-wide
                            // batches keep working but are labeled.
                            Text(
                              b.isLegacy
                                  ? 'Legacy (tier-wide) · ${b.tier}'
                                  : '${b.productName ?? 'Product'} · ${b.tier}',
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _StatusChip(
                                    label: b.state,
                                    color: _batchStateColor(b.state)),
                                if (b.isLegacy)
                                  _StatusChip(
                                      label: 'LEGACY',
                                      color: AppTheme.warning),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_outlined,
                          color: AppTheme.primary),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Progress = reservations + paid units (§2.3), both
                      // broken out so the admin sees what's real money.
                      Text(
                          '${b.reservedCount} reserved + ${b.paidCount} paid / ${b.moqTarget}',
                          style:
                              const TextStyle(color: AppTheme.textSecondary)),
                      Text('${(pct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: AppTheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(
                          pct >= 1 ? AppTheme.success : AppTheme.primary),
                    ),
                  ),
                  if (b.etaNote != null && b.etaNote!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_outlined,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(b.etaNote!,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  InkWell(
                    onTap: () => marketPush(
                        context, HardwareBatchOrdersScreen(batch: b)),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_outlined,
                              size: 16, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text('View orders (${b.orderCount})',
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          const Spacer(),
                          const Icon(Icons.chevron_right,
                              size: 18, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Orders (fulfillment board) ─────────────────────────────────────────────

  /// Chip label → `?status=` param (null = all) for the filter row (§2.7).
  static const _orderFilters = <String, String?>{
    'All': null,
    'Awaiting payment': 'awaitingPayment',
    'Reserved': 'reserved',
    'Paid': 'paid',
    'In production': 'inProduction',
    'Shipping': 'shipping',
    'At hub': 'atHub',
    'Delivered': 'delivered',
    'Installed': 'installed',
    'Cancelled': 'cancelled',
  };

  Widget _ordersList(HardwareProvider p) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _orderFilters.entries.map((e) {
              final selected = p.ordersStatusFilter == e.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(e.key),
                  selected: selected,
                  onSelected: (_) => p.setOrdersStatusFilter(e.value),
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(child: _ordersBoard(p)),
      ],
    );
  }

  Widget _ordersBoard(HardwareProvider p) {
    if (p.orders.isEmpty) {
      // Failed first page → retry (§WS6.2); otherwise a normal empty state.
      if (p.ordersError != null) {
        return EmptyView(
          icon: Icons.wifi_off_rounded,
          message: 'Couldn\'t load orders',
          subtitle: p.ordersError,
          action: ElevatedButton.icon(
            onPressed: () => p.reloadOrders(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        );
      }
      return EmptyView(
        icon: Icons.receipt_long_outlined,
        message: p.ordersStatusFilter == null
            ? 'No hardware orders yet'
            : 'No matching orders',
        subtitle: p.ordersStatusFilter == null
            ? 'Orders will appear here when placed'
            : 'Nothing with this status right now',
      );
    }
    return RefreshIndicator(
      onRefresh: () => p.reloadOrders(),
      child: ListView.separated(
        controller: _ordersScroll,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: p.orders.length + (p.ordersHasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i >= p.orders.length) {
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
          return _orderCard(p, p.orders[i]);
        },
      ),
    );
  }

  Widget _orderCard(HardwareProvider p, HwOrder o) {
    final canOpenVendor = o.vendor != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _orderStatusColor(o.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.shopping_cart_outlined,
                      color: _orderStatusColor(o.status)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${o.productName} ×${o.quantity}',
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      // Tappable vendor → VendorDetailScreen (§2.3).
                      InkWell(
                        onTap: canOpenVendor ? () => _openVendor(o) : null,
                        child: Row(
                          children: [
                            Icon(Icons.storefront_outlined,
                                size: 14,
                                color: canOpenVendor
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                o.vendorName,
                                style: TextStyle(
                                  color: canOpenVendor
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  decoration: canOpenVendor
                                      ? TextDecoration.underline
                                      : null,
                                ),
                              ),
                            ),
                            if (canOpenVendor)
                              const Icon(Icons.chevron_right,
                                  size: 16, color: AppTheme.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Primary chip is the real order STATUS — mode is only a muted
                // secondary tag. (Previously mode was the big chip, so a
                // reserved paid-mode order read as "paid" — display lie, §2.7.)
                _StatusChip(
                    label: _statusLabel(o.status),
                    color: _orderStatusColor(o.status)),
                _StatusChip(
                    label: o.mode == 'paid' ? 'PAID MODE' : 'RESERVATION',
                    color: AppTheme.textSecondary),
                if (o.withBranding)
                  _StatusChip(label: 'Branded', color: AppTheme.accent),
                if (o.batchId != null)
                  _StatusChip(label: 'Batched', color: AppTheme.textSecondary),
                if (o.amountNaira != null || o.mode == 'paid')
                  Text('₦${o.amountNaira ?? 0}',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600)),
                if (o.createdAt != null)
                  Text(_fmtDate(o.createdAt!),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
            if (o.cancelReason != null && o.cancelReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Cancelled: ${o.cancelReason == 'payment_expired' ? 'payment window expired' : o.cancelReason}',
                  style: const TextStyle(color: AppTheme.danger, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Status',
                    style: TextStyle(color: AppTheme.textSecondary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: o.status,
                      dropdownColor: AppTheme.surface,
                      items: HwOrder.statuses
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) async {
                        if (v == null || v == o.status) return;
                        // Manually setting "paid" bypasses the payment flow —
                        // make the admin confirm it (§2.7).
                        if (v == 'paid') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: AppTheme.surface,
                              title: const Text('Mark as paid?'),
                              content: const Text(
                                  'This marks the order as paid without a '
                                  'payment record — continue?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Mark paid',
                                        style: TextStyle(
                                            color: AppTheme.warning))),
                              ],
                            ),
                          );
                          if (ok != true || !mounted) return;
                        }
                        if (!mounted) return;
                        final err = await context
                            .read<HardwareProvider>()
                            .updateOrder(o.id, {'status': v});
                        _toast(err ?? 'Status updated', isError: err != null);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openVendor(HwOrder o) async {
    final v = o.vendor;
    if (v == null) return;
    await marketPush(
        context, VendorDetailScreen(vendorId: v.id, lite: v));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Color _batchStateColor(String state) {
    switch (state) {
      case 'collecting':
        return AppTheme.warning;
      case 'producing':
        return AppTheme.primary;
      case 'shipping':
        return AppTheme.accent;
      case 'fulfilling':
        return AppTheme.primary;
      case 'closed':
        return AppTheme.success;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _orderStatusColor(String status) {
    switch (status) {
      case 'awaitingPayment':
        return AppTheme.warning;
      case 'reserved':
        return AppTheme.accent;
      case 'paid':
        return AppTheme.success;
      case 'inProduction':
        return AppTheme.primary;
      case 'shipping':
        return AppTheme.accent;
      case 'atHub':
        return AppTheme.accent;
      case 'delivered':
        return AppTheme.success;
      case 'installed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.danger;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'awaitingPayment':
        return 'Awaiting payment';
      case 'inProduction':
        return 'In production';
      case 'atHub':
        return 'At hub';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w800),
        ),
      );
}
