import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../marketPlacePush.dart';
import '../../models/hardware_model.dart';
import '../../providers/hardware_provider.dart';
import '../vendor_detail_screen.dart';

/// Member orders of one batch (§3 "View orders (N)") — cursor-paginated list
/// backed by GET /admin/hardware/batch/:id/orders. Read-only board: status
/// changes still happen from the main orders board.
class HardwareBatchOrdersScreen extends StatefulWidget {
  const HardwareBatchOrdersScreen({super.key, required this.batch});

  final HwBatch batch;

  @override
  State<HardwareBatchOrdersScreen> createState() =>
      _HardwareBatchOrdersScreenState();
}

class _HardwareBatchOrdersScreenState extends State<HardwareBatchOrdersScreen> {
  final _scroll = ScrollController();
  final List<HwOrder> _orders = [];
  String? _cursor;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context
          .read<HardwareProvider>()
          .getBatchOrders(widget.batch.id);
      if (!mounted) return;
      setState(() {
        _orders
          ..clear()
          ..addAll(page.items);
        _cursor = page.nextCursor;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _maybeLoadMore() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _cursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await context
          .read<HardwareProvider>()
          .getBatchOrders(widget.batch.id, cursor: _cursor);
      if (!mounted) return;
      setState(() {
        _orders.addAll(page.items);
        _cursor = page.nextCursor;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.batch;
    final title = b.isLegacy
        ? 'Legacy ${b.tier} batch'
        : '${b.productName ?? 'Product'} · ${b.tier}';
    return Scaffold(
      appBar: AppBar(title: Text('Orders — $title')),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _loadFirstPage);
    }
    if (_orders.isEmpty) {
      return const EmptyView(
        icon: Icons.receipt_long_outlined,
        message: 'No orders in this batch',
        subtitle: 'Orders join when vendors reserve or pay',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _orders.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i >= _orders.length) {
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
          return _orderCard(_orders[i]);
        },
      ),
    );
  }

  Widget _orderCard(HwOrder o) {
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hwOrderStatusColor(o.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.shopping_cart_outlined,
                      size: 20, color: hwOrderStatusColor(o.status)),
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
                      InkWell(
                        onTap: canOpenVendor
                            ? () => marketPush(
                                context,
                                VendorDetailScreen(
                                    vendorId: o.vendor!.id, lite: o.vendor))
                            : null,
                        child: Text(
                          o.vendorName,
                          style: TextStyle(
                            color: canOpenVendor
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            decoration: canOpenVendor
                                ? TextDecoration.underline
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _chip(hwOrderStatusLabel(o.status),
                    hwOrderStatusColor(o.status)),
                _chip(o.mode == 'paid' ? 'PAID MODE' : 'RESERVATION',
                    AppTheme.textSecondary),
                if (o.withBranding) _chip('Branded', AppTheme.accent),
                if (o.amountNaira != null || o.mode == 'paid')
                  Text('₦${o.amountNaira ?? 0}',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600)),
              ],
            ),
            if (o.cancelReason != null && o.cancelReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Cancelled: ${o.cancelReason == 'payment_expired' ? 'payment window expired' : o.cancelReason}',
                  style:
                      const TextStyle(color: AppTheme.danger, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
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

/// Order status → color, shared between the hardware boards.
Color hwOrderStatusColor(String status) {
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

String hwOrderStatusLabel(String status) {
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
