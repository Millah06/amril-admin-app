import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_grid.dart';
import '../../dashboard/stat_card.dart';
import '../providers/dashboard_provider.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketDashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<MarketDashboardProvider>().load(),
          ),
        ],
      ),
      body: Consumer<MarketDashboardProvider>(
        builder: (_, provider, __) {
          if (provider.loading) return const LoadingGrid();
          if (provider.error != null) {
            return ErrorView(
              message: provider.error!,
              onRetry: () => provider.load(),
            );
          }

          if (provider.error != null) {
            return ErrorView(
              message: provider.error!,
              onRetry: () => provider.load(),
            );
          }

          final s = provider.stats;
          
          if (s == null) {
            return ErrorView(message: 'UnExpected');
          }

          return RefreshIndicator(
            onRefresh: () => provider.load(silent: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Vendors & Appeals ──────────────────────────────────
                const _SectionLabel('Activity'),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                  children: [
                    StatCard(
                      label: 'Pending Vendors',
                      value: s!.pendingVendors.toString(),
                      icon: Icons.store_outlined,
                      iconColor: s.pendingVendors > 0
                          ? AppTheme.warning
                          : AppTheme.success,
                      iconBg: (s.pendingVendors > 0
                          ? AppTheme.warning
                          : AppTheme.success)
                          .withOpacity(0.1),
                      subtitle: s.pendingVendors > 0
                          ? 'Awaiting review'
                          : 'All clear',
                    ),
                    StatCard(
                      label: 'Active Appeals',
                      value: s.activeAppeals.toString(),
                      icon: Icons.gavel_rounded,
                      iconColor: s.activeAppeals > 0
                          ? AppTheme.danger
                          : AppTheme.success,
                      iconBg: (s.activeAppeals > 0
                          ? AppTheme.danger
                          : AppTheme.success)
                          .withOpacity(0.1),
                      subtitle: s.activeAppeals > 0
                          ? 'Need resolution'
                          : 'None open',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Platform Balances ──────────────────────────────────
                const _SectionLabel('Platform Balances'),
                const SizedBox(height: 10),
                WideStatCard(
                  label: 'Total Available',
                  value: AppFormatters.naira(s.totalAvailableBalance),
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppTheme.success,
                  children: [
                    _BalanceRow(
                      label: 'Locked (Escrow)',
                      value: AppFormatters.naira(s.totalLockedBalance),
                      color: AppTheme.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Transactions ───────────────────────────────────────
                const _SectionLabel('Successful Transactions'),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.check_circle_rounded,
                              color: AppTheme.success, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${s.successTxCount} transactions',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Total volume',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          AppFormatters.naira(s.successTxVolume),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppTheme.textSecondary,
      letterSpacing: 0.4,
    ),
  );
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 13)),
      Text(value,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13)),
    ],
  );
}
