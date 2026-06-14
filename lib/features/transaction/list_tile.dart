import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import 'model.dart';

class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    super.key,
    required this.tx,
    this.onRefund,
  });

  final AdminTransaction tx;
  final VoidCallback? onRefund;

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.isCredit;
    final color = isCredit ? AppTheme.success : AppTheme.danger;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                // Message + user
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.message ?? (isCredit ? 'Credit' : 'Debit'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tx.userName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          tx.userName!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Amount
                Text(
                  '${isCredit ? '+' : '-'}${AppFormatters.naira(tx.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusBadge(status: tx.status),
                const SizedBox(width: 8),
                if (tx.transactionRef != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: tx.transactionRef!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reference copied'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.tag, size: 11, color: AppTheme.textSecondary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              tx.transactionRef!,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.copy, size: 10, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  AppFormatters.timeAgo(tx.createdAt),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                if (tx.canBeRefunded && onRefund != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onRefund,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
                      ),
                      child: const Text(
                        'Refund',
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
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