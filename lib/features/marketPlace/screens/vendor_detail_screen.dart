import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../models/appeal_model.dart';
import '../providers/appeal_provider.dart';
import 'order_chat_view.dart';

/// Shows full order details for an appealed order + a live Firestore chat.
/// The admin can read the conversation then hit Resolve to release or refund.
class AppealDetailScreen extends StatefulWidget {
  const AppealDetailScreen({super.key, required this.appeal});

  final AppealOrder appeal;

  @override
  State<AppealDetailScreen> createState() => _AppealDetailScreenState();
}

class _AppealDetailScreenState extends State<AppealDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    String? decision;
    String? reason;

    // Step 1 — pick the decision
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => _ResolutionDialog(appeal: widget.appeal),
    );
    if (picked == null || !mounted) return;

    // picked format: "decision||reason"
    final parts = picked.split('||');
    decision = parts[0];
    reason = parts.length > 1 ? parts[1] : null;

    // Step 2 — final confirm
    final label = decision == 'release_vendor'
        ? 'Release to vendor'
        : 'Refund to customer';
    final color =
    decision == 'release_vendor' ? AppTheme.success : AppTheme.danger;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Resolution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Decision: ',
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: color, fontSize: 15)),
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Reason: $reason',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final err = await context.read<AppealProvider>().resolve(
      orderId: widget.appeal.id,
      decision: decision,
      reason: reason,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'Appeal resolved ✓'),
      backgroundColor: err != null ? AppTheme.danger : AppTheme.success,
      behavior: SnackBarBehavior.floating,
    ));

    if (err == null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final appeal = widget.appeal;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order #${appeal.id.substring(0, 8).toUpperCase()}',
          style: const TextStyle(fontSize: 15),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Chat'),
          ],
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.accent,
        ),
        actions: [
          Consumer<AppealProvider>(
            builder: (_, p, __) => p.resolvingId == appeal.id
                ? const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : TextButton.icon(
              onPressed: _resolve,
              icon: const Icon(Icons.gavel_rounded, size: 16),
              label: const Text('Resolve',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accent,
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Details tab ─────────────────────────────────────────────
          _DetailsTab(appeal: appeal),

          // ── Chat tab ────────────────────────────────────────────────
          Consumer<AppealProvider>(
            builder: (_, provider, __) => OrderChatView(
              chatId: appeal.id,
              isSending: provider.sendingMessage,
              senderLabel: 'Admin Support',
              inputHint: 'Send a message to the parties…',
              onSend: (msg) {
                print('😂 ${appeal.id}');
                return provider.sendMessage(
                  orderId: appeal.id,
                  message: msg,
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}

// ── Details tab ───────────────────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.appeal});
  final AppealOrder appeal;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Escrow info ────────────────────────────────────────────────
        if (appeal.escrow != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Escrow'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _EscrowTile(
                          label: 'Held',
                          value: AppFormatters.naira(
                              appeal.escrow!.amountHeld),
                          color: AppTheme.warning,
                        ),
                      ),
                      Expanded(
                        child: _EscrowTile(
                          label: 'Commission',
                          value: AppFormatters.naira(
                              appeal.escrow!.commission),
                          color: AppTheme.accent,
                        ),
                      ),
                      Expanded(
                        child: _EscrowTile(
                          label: 'Payout',
                          value: AppFormatters.naira(
                              appeal.escrow!.amountHeld -
                                  appeal.escrow!.commission),
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                  if (appeal.escrow!.appealReason != null &&
                      appeal.escrow!.appealReason!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    const Text('Appeal Reason',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Text(appeal.escrow!.appealReason!,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textPrimary)),
                  ],
                  const SizedBox(height: 10),
                  InfoRow(
                    label: 'Auto Release',
                    value: AppFormatters.dateTime(
                        appeal.escrow!.autoReleaseAt),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // ── Order Info ─────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Order Info'),
                const SizedBox(height: 12),
                InfoRow(label: 'Vendor', value: appeal.vendorName),
                InfoRow(
                    label: 'Total',
                    value: AppFormatters.naira(appeal.totalAmount)),
                InfoRow(
                    label: 'Delivery',
                    value: [
                      appeal.deliveryArea,
                      appeal.deliveryLga,
                      appeal.deliveryState
                    ]
                        .where((s) => s.isNotEmpty)
                        .join(', ')),
                InfoRow(
                    label: 'Opened',
                    value: AppFormatters.dateTime(appeal.createdAt)),
                InfoRow(
                    label: 'Appealed',
                    value: AppFormatters.dateTime(appeal.updatedAt)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Order Items ────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle('Items (${appeal.items.length})'),
                const SizedBox(height: 8),
                ...appeal.items.map(
                      (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '×${item.quantity}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accent),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(item.name,
                              style: const TextStyle(fontSize: 13)),
                        ),
                        Text(
                          AppFormatters.naira(item.price * item.quantity),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      AppFormatters.naira(appeal.totalAmount),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Resolution Dialog ─────────────────────────────────────────────────────────

class _ResolutionDialog extends StatefulWidget {
  const _ResolutionDialog({required this.appeal});
  final AppealOrder appeal;

  @override
  State<_ResolutionDialog> createState() => _ResolutionDialogState();
}

class _ResolutionDialogState extends State<_ResolutionDialog> {
  String _decision = 'release_vendor';
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Resolve Appeal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decision toggle
          Row(
            children: [
              Expanded(
                child: _DecisionTile(
                  label: 'Release\nto Vendor',
                  icon: Icons.store_rounded,
                  color: AppTheme.success,
                  selected: _decision == 'release_vendor',
                  onTap: () =>
                      setState(() => _decision = 'release_vendor'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DecisionTile(
                  label: 'Refund\nto Customer',
                  icon: Icons.person_rounded,
                  color: AppTheme.danger,
                  selected: _decision == 'refund_user',
                  onTap: () =>
                      setState(() => _decision = 'refund_user'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'e.g. Item not delivered',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            '$_decision||${_reasonCtrl.text.trim()}',
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _DecisionTile extends StatelessWidget {
  const _DecisionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.08) : AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: selected ? color : AppTheme.divider,
            width: selected ? 1.5 : 1),
      ),
      child: Column(
        children: [
          Icon(icon,
              color: selected ? color : AppTheme.textSecondary,
              size: 22),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
              selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? color : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3),
  );
}

class _EscrowTile extends StatelessWidget {
  const _EscrowTile(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(
              fontSize: 11, color: AppTheme.textSecondary)),
    ],
  );
}