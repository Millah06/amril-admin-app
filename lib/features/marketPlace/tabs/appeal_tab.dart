import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_list.dart';
import '../models/appeal_model.dart';
import '../providers/appeal_provider.dart';
import '../screens/appeal_detail_screen.dart';
import '../screens/vendor_detail_screen.dart';

class AppealTab extends StatefulWidget {
  const AppealTab({super.key});

  @override
  State<AppealTab> createState() => _AppealTabState();
}

class _AppealTabState extends State<AppealTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppealProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppealProvider>(
          builder: (_, p, __) =>
              Text('Appeals${p.count > 0 ? ' (${p.count})' : ''}'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<AppealProvider>().load(),
          ),
        ],
      ),
      body: Consumer<AppealProvider>(
        builder: (_, provider, __) {
          if (provider.loading) return const LoadingList();
          if (provider.error != null) {
            return ErrorView(
              message: provider.error!,
              onRetry: () => provider.load(),
            );
          }
          if (provider.appeals.isEmpty) {
            return const EmptyView(
              icon: Icons.gavel_rounded,
              message: 'No active appeals',
              subtitle: 'All disputes have been resolved',
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.load(silent: true),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: provider.appeals.length,
              itemBuilder: (_, i) {
                final appeal = provider.appeals[i];
                final isResolving = provider.resolvingId == appeal.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AppealCard(
                    appeal: appeal,
                    isResolving: isResolving,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: provider,
                          child: AppealDetailScreen(appeal: appeal),
                        ),
                      ),
                    ).then((_) => provider.load(silent: true)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Appeal card ───────────────────────────────────────────────────────────────

class _AppealCard extends StatelessWidget {
  const _AppealCard({
    required this.appeal,
    required this.onTap,
    this.isResolving = false,
  });

  final AppealOrder appeal;
  final VoidCallback onTap;
  final bool isResolving;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: isResolving ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.gavel_rounded,
                        color: AppTheme.danger, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appeal.vendorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Order #${appeal.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (isResolving)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppTheme.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Amount held
                  Expanded(
                    child: _InfoPill(
                      icon: Icons.lock_outline_rounded,
                      label: 'Held',
                      value: AppFormatters.naira(
                          appeal.escrow?.amountHeld ?? appeal.totalAmount),
                      valueColor: AppTheme.warning,
                    ),
                  ),
                  // Item count
                  Expanded(
                    child: _InfoPill(
                      icon: Icons.receipt_outlined,
                      label: 'Items',
                      value: '${appeal.items.length}',
                    ),
                  ),
                  // Open duration
                  Expanded(
                    child: _InfoPill(
                      icon: Icons.schedule_rounded,
                      label: 'Open',
                      value: appeal.openDuration,
                      valueColor: AppTheme.danger,
                    ),
                  ),
                ],
              ),
              // Appeal reason if available
              if (appeal.escrow?.appealReason != null &&
                  appeal.escrow!.appealReason!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.danger.withOpacity(0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 13, color: AppTheme.danger),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          appeal.escrow!.appealReason!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, size: 14, color: AppTheme.textSecondary),
      const SizedBox(height: 3),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: valueColor ?? AppTheme.textPrimary,
        ),
      ),
      Text(label,
          style: const TextStyle(
              fontSize: 10, color: AppTheme.textSecondary)),
    ],
  );
}