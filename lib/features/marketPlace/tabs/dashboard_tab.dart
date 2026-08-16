import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
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

          final s = provider.stats;
          if (s == null) {
            return ErrorView(message: 'Unexpected error');
          }

          // Overview is the marketplace section's home. It shows ONLY
          // marketplace-specific triage (vendors + appeals). Platform balances
          // and transaction totals live on the app-level dashboard — kept out of
          // here so the owner isn't shown two overlapping dashboards (§7).
          return RefreshIndicator(
            onRefresh: () => provider.load(silent: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _SectionLabel('Needs attention'),
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
                      value: s.pendingVendors.toString(),
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
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.insights_rounded,
                          color: AppTheme.textSecondary, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Platform balances and transaction totals are on the '
                          'main Dashboard.',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12.5),
                        ),
                      ),
                    ],
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

