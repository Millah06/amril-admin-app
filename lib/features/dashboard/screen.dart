import 'package:admin_panel/features/dashboard/provider.dart';
import 'package:admin_panel/features/dashboard/stat_card.dart';
import 'package:admin_panel/features/marketPlace/shell.dart';
import 'package:admin_panel/features/partner/partner_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_grid.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => context.read<DashboardProvider>().load(),
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
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
            return ErrorView(message: 'Unexpected');
          }

          return RefreshIndicator(
            onRefresh: () => provider.load(silent: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Marketplace ─────────────────────────────────────────────
                _SectionHeader(title: 'Marketplace', icon: Icons.storefront_outlined),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.storefront_rounded, color: AppTheme.primary),
                    title: const Text(
                      'Manage Marketplace',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text('Vendors, Hardware, Appeals & Configs'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MarketPlaceShell()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── Users ─────────────────────────────────────────────────
                _SectionHeader(title: 'Users', icon: Icons.people_alt_outlined),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                  children: [
                    StatCard(
                      label: 'Total Users',
                      value: AppFormatters.compact(s.users.total),
                      icon: Icons.people_rounded,
                      subtitle: '+${s.users.newToday} today',
                    ),
                    StatCard(
                      label: 'Active Users',
                      value: AppFormatters.compact(s.users.active),
                      icon: Icons.check_circle_outline,
                      iconColor: AppTheme.success,
                      iconBg: AppTheme.success.withValues(alpha: 0.1),
                    ),
                    StatCard(
                      label: 'Blocked Users',
                      value: s.users.blocked.toString(),
                      icon: Icons.block_rounded,
                      iconColor: AppTheme.danger,
                      iconBg: AppTheme.danger.withValues(alpha: 0.1),
                    ),
                    StatCard(
                      label: 'KYC Pending',
                      value: s.kyc.pending.toString(),
                      icon: Icons.hourglass_empty_rounded,
                      iconColor: AppTheme.warning,
                      iconBg: AppTheme.warning.withValues(alpha: 0.1),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Partners ──────────────────────────────────────────────
                _SectionHeader(title: 'Partners', icon: Icons.handshake_outlined),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.handshake_rounded, color: AppTheme.primary),
                    title: const Text(
                      'Manage Partners',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text('Partner codes, vendor assignments & commission payouts'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PartnerListScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── Balances ───────────────────────────────────────────────
                _SectionHeader(title: 'Platform Balances', icon: Icons.account_balance_wallet_outlined),
                const SizedBox(height: 12),
                WideStatCard(
                  label: 'Total Available Balance',
                  value: AppFormatters.naira(s.balances.totalAvailable),
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppTheme.success,
                  children: [
                    _BalanceRow(
                      label: 'Locked Balance',
                      value: AppFormatters.naira(s.balances.totalLocked),
                      color: AppTheme.warning,
                    ),
                    const SizedBox(height: 8),
                    _BalanceRow(
                      label: 'Reward Balance',
                      value: AppFormatters.naira(s.balances.totalRewards),
                      color: AppTheme.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Transactions ────────────────────────────────────────────
                _SectionHeader(title: 'Transactions', icon: Icons.receipt_long_outlined),
                const SizedBox(height: 12),
                ...(s.transactions.entries.map(
                      (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TxStatusRow(status: e.key, stat: e.value),
                  ),
                )),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Private helpers ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TxStatusRow extends StatelessWidget {
  const _TxStatusRow({required this.status, required this.stat});

  final String status;
  final dynamic stat;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'success':
        color = AppTheme.success;
        icon = Icons.check_circle_rounded;
        break;
      case 'pending':
        color = AppTheme.warning;
        icon = Icons.hourglass_bottom_rounded;
        break;
      default:
        color = AppTheme.danger;
        icon = Icons.cancel_rounded;
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          AppFormatters.titleCase(status),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text('${stat.count} transactions'),
        trailing: Text(
          AppFormatters.naira(stat.volume),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}