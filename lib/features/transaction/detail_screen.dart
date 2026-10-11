import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/erorrs/app_exception.dart';
import '../../../shared/widgets/error_view.dart';
import '../users/user_detail_screen.dart';

import 'model.dart';
import 'service.dart';

/// Internal metaData keys that are noise to an admin reading the detail
/// screen — surfaced elsewhere (or not at all) rather than in the raw list.
const _hiddenMetaKeys = {
  'channel',
  'entityType',
  'entityId',
  'paymentId',
  'provider',
  'direction',
  'rewardPlan',
  'clientRequestId',
  'performedBy',
  'transferTo',
  'transferFrom',
  'kind',
  'refundOf',
};

/// Prettifies a camelCase key: "vtpassRef" → "Vtpass Ref".
String _prettifyKey(String key) {
  final withSpaces = key.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (m) => '${m[1]} ${m[2]}',
  );
  final words = withSpaces.split(RegExp(r'[\s_]+'));
  return words
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _service = TransactionsService();

  AdminTransactionDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _service.getTransactionDetail(widget.transactionId);
      if (!mounted) return;
      setState(() => _detail = detail);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Detail')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildBody(_detail!),
    );
  }

  Widget _buildBody(AdminTransactionDetail detail) {
    final tx = detail.tx;
    final isCredit = tx.isCredit;
    final color = isCredit ? AppTheme.success : AppTheme.danger;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Amount card ──────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    tx.displayLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isCredit ? '+' : '-'}${AppFormatters.naira(tx.amount)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusBadge(status: tx.status),
                      const SizedBox(width: 8),
                      Text(
                        AppFormatters.dateTime(tx.createdAt),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (tx.message != null && tx.message!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      tx.message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── References ───────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('References'),
                  const SizedBox(height: 10),
                  if (tx.humanRef != null)
                    _CopyableRow(label: 'Reference', value: tx.humanRef!, onCopy: _copy),
                  if (tx.transactionRef != null)
                    _CopyableRow(
                      label: 'Transaction Ref',
                      value: tx.transactionRef!,
                      onCopy: _copy,
                    ),
                  _CopyableRow(label: 'Transaction ID', value: tx.id, onCopy: _copy),
                  if (tx.orderId != null)
                    _CopyableRow(label: 'Order ID', value: tx.orderId!, onCopy: _copy),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── User ─────────────────────────────────────────────────────────
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserDetailScreen(userId: detail.user.id),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.accent.withOpacity(0.12),
                      child: Text(
                        detail.user.name.isNotEmpty
                            ? detail.user.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.user.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            detail.user.email,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          if (detail.user.phone != null && detail.user.phone!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              detail.user.phone!,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Delivery (e.g. electricity token) ───────────────────────────
          if (detail.delivery != null) ...[
            _DeliveryCard(delivery: detail.delivery!, onCopy: _copy),
            const SizedBox(height: 12),
          ],

          // ── Payment ──────────────────────────────────────────────────────
          if (detail.payment != null) ...[
            _PaymentCard(payment: detail.payment!, onCopy: _copy),
            const SizedBox(height: 12),
          ],

          // ── Refund ───────────────────────────────────────────────────────
          if (detail.refund != null) ...[
            _RefundCard(refund: detail.refund!, onCopy: _copy),
            const SizedBox(height: 12),
          ],

          // ── Metadata ─────────────────────────────────────────────────────
          if (tx.metaData != null && tx.metaData!.isNotEmpty)
            _MetaDataCard(metaData: tx.metaData!),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppTheme.textSecondary,
          letterSpacing: 0.3,
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color get _color {
    switch (status) {
      case 'success':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      default:
        return AppTheme.danger;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            color: _color,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _CopyableRow extends StatelessWidget {
  const _CopyableRow({required this.label, required this.value, required this.onCopy});
  final String label;
  final String value;
  final void Function(String label, String value) onCopy;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => onCopy(label, value),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.copy, size: 14, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      );
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery, required this.onCopy});
  final TxDelivery delivery;
  final void Function(String label, String value) onCopy;

  @override
  Widget build(BuildContext context) {
    final token = delivery.token ?? delivery.tokens;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Delivery'),
            const SizedBox(height: 10),
            if (token != null && token.isNotEmpty) ...[
              GestureDetector(
                onTap: () => onCopy('Token', token),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOKEN',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              token,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.copy, size: 18, color: AppTheme.accent),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (delivery.units != null)
              _CopyableRow(label: 'Units', value: delivery.units!, onCopy: onCopy),
            if (delivery.productName != null)
              _CopyableRow(label: 'Product', value: delivery.productName!, onCopy: onCopy),
            if (delivery.customerName != null)
              _CopyableRow(label: 'Customer', value: delivery.customerName!, onCopy: onCopy),
            if (delivery.status != null)
              _CopyableRow(label: 'Status', value: delivery.status!, onCopy: onCopy),
            if (delivery.vtpassRef != null)
              _CopyableRow(label: 'VTPass Ref', value: delivery.vtpassRef!, onCopy: onCopy),
            if (delivery.bonusEarned != null)
              _CopyableRow(label: 'Bonus Earned', value: delivery.bonusEarned!, onCopy: onCopy),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment, required this.onCopy});
  final TxPayment payment;
  final void Function(String label, String value) onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _SectionTitle('Payment'),
                const Spacer(),
                if (payment.webhookVerified != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (payment.webhookVerified!
                              ? AppTheme.success
                              : AppTheme.warning)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      payment.webhookVerified! ? 'WEBHOOK VERIFIED' : 'UNVERIFIED',
                      style: TextStyle(
                        color: payment.webhookVerified! ? AppTheme.success : AppTheme.warning,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (payment.provider != null)
              _CopyableRow(label: 'Provider', value: payment.provider!, onCopy: onCopy),
            if (payment.providerRef != null)
              _CopyableRow(label: 'Provider Ref', value: payment.providerRef!, onCopy: onCopy),
            if (payment.status != null)
              _CopyableRow(label: 'Status', value: payment.status!, onCopy: onCopy),
            if (payment.entityType != null)
              _CopyableRow(label: 'Entity Type', value: payment.entityType!, onCopy: onCopy),
            if (payment.id != null)
              _CopyableRow(label: 'Payment ID', value: payment.id!, onCopy: onCopy),
          ],
        ),
      ),
    );
  }
}

class _RefundCard extends StatelessWidget {
  const _RefundCard({required this.refund, required this.onCopy});
  final TxRefund refund;
  final void Function(String label, String value) onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Refund'),
            const SizedBox(height: 10),
            if (refund.amount != null)
              _CopyableRow(
                label: 'Amount',
                value: AppFormatters.naira(refund.amount!),
                onCopy: onCopy,
              ),
            if (refund.transactionRef != null)
              _CopyableRow(
                label: 'Refund Ref',
                value: refund.transactionRef!,
                onCopy: onCopy,
              ),
            if (refund.createdAt != null)
              _CopyableRow(
                label: 'Refunded On',
                value: AppFormatters.dateTime(refund.createdAt!),
                onCopy: onCopy,
              ),
            if (refund.id != null)
              _CopyableRow(label: 'Refund ID', value: refund.id!, onCopy: onCopy),
          ],
        ),
      ),
    );
  }
}

class _MetaDataCard extends StatelessWidget {
  const _MetaDataCard({required this.metaData});
  final Map<String, dynamic> metaData;

  @override
  Widget build(BuildContext context) {
    final entries = metaData.entries
        .where((e) => !_hiddenMetaKeys.contains(e.key) && e.value != null)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Additional Info'),
            const SizedBox(height: 10),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        _prettifyKey(e.key),
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value.toString(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

