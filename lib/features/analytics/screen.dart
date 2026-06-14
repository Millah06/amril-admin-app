import 'package:admin_panel/features/analytics/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_list.dart';
import 'model.dart';


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<AnalyticsProvider>().load(),
          ),
        ],
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (_, provider, __) {
          if (provider.loading) return const LoadingList();
          if (provider.error != null) {
            return ErrorView(message: provider.error!, onRetry: () => provider.load());
          }

          return RefreshIndicator(
            onRefresh: () => provider.load(silent: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Balance Summary ────────────────────────────────────────
                if (provider.balanceSummary != null)
                  _BalanceSummaryCard(summary: provider.balanceSummary!),
                const SizedBox(height: 20),

                // ── Top by Volume ──────────────────────────────────────────
                _SectionHeader(
                  title: 'Top Users by Volume',
                  trailing: _PeriodPicker(
                    selected: provider.period,
                    onChanged: provider.setPeriod,
                  ),
                ),
                const SizedBox(height: 8),
                // Type toggle
                _TypeToggle(
                  selected: provider.volumeType,
                  onChanged: provider.setVolumeType,
                ),
                const SizedBox(height: 12),
                if (provider.topByVolume.isEmpty)
                  const _EmptyLeaderboard()
                else
                  ...provider.topByVolume.asMap().entries.map(
                        (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _VolumeLeaderboardTile(
                        rank: e.key + 1,
                        item: e.value,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Top by Balance ─────────────────────────────────────────
                const _SectionHeader(title: 'Top Wallet Balances'),
                const SizedBox(height: 12),
                if (provider.topByBalance.isEmpty)
                  const _EmptyLeaderboard()
                else
                  ...provider.topByBalance.asMap().entries.map(
                        (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _BalanceLeaderboardTile(
                        rank: e.key + 1,
                        item: e.value,
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

// ── Balance Summary Card ──────────────────────────────────────────────────────

class _BalanceSummaryCard extends StatelessWidget {
  const _BalanceSummaryCard({required this.summary});
  final BalanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: AppTheme.success, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Platform Balance Sheet',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SummaryRow(
              label: 'Total Available',
              value: AppFormatters.naira(summary.totalAvailable),
              color: AppTheme.success,
              isLarge: true,
            ),
            const Divider(height: 20),
            _SummaryRow(
              label: 'Total Locked',
              value: AppFormatters.naira(summary.totalLocked),
              color: AppTheme.warning,
            ),
            const SizedBox(height: 10),
            _SummaryRow(
              label: 'Total Rewards',
              value: AppFormatters.naira(summary.totalRewards),
              color: AppTheme.accent,
            ),
            const SizedBox(height: 10),
            _SummaryRow(
              label: 'Average Balance',
              value: AppFormatters.naira(summary.averageBalance),
              color: AppTheme.textPrimary,
            ),
            const SizedBox(height: 10),
            _SummaryRow(
              label: 'Wallets with Balance',
              value: summary.walletsWithPositiveBalance.toString(),
              color: AppTheme.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.isLarge = false,
  });
  final String label;
  final String value;
  final Color color;
  final bool isLarge;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      ),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: isLarge ? 18 : 13,
        ),
      ),
    ],
  );
}

// ── Leaderboard Tiles ─────────────────────────────────────────────────────────

class _VolumeLeaderboardTile extends StatelessWidget {
  const _VolumeLeaderboardTile({required this.rank, required this.item});
  final int rank;
  final TopUserByVolume item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _RankBadge(rank: rank),
            const SizedBox(width: 12),
            _UserAvatar(name: item.userName, url: item.avatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.userName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                    '${item.transactionCount} transactions',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              AppFormatters.naira(item.totalVolume),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceLeaderboardTile extends StatelessWidget {
  const _BalanceLeaderboardTile({required this.rank, required this.item});
  final int rank;
  final TopUserByBalance item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _RankBadge(rank: rank),
            const SizedBox(width: 12),
            _UserAvatar(name: item.userName, url: item.avatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.userName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  if (item.lockedBalance > 0)
                    Text(
                      'Locked: ${AppFormatters.naira(item.lockedBalance)}',
                      style: const TextStyle(color: AppTheme.warning, fontSize: 11),
                    ),
                ],
              ),
            ),
            Text(
              AppFormatters.naira(item.availableBalance),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppTheme.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  Color get _color {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: _color.withOpacity(rank <= 3 ? 0.15 : 0.08),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(
      '#$rank',
      style: TextStyle(
        color: rank <= 3 ? _color : AppTheme.textSecondary,
        fontWeight: FontWeight.w800,
        fontSize: 10,
      ),
    ),
  );
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name, this.url});
  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 18,
    backgroundColor: AppTheme.accent.withOpacity(0.1),
    backgroundImage:
    (url != null && url!.isNotEmpty) ? CachedNetworkImageProvider(url!) : null,
    child: (url == null || url!.isEmpty)
        ? Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(
        color: AppTheme.accent,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    )
        : null,
  );
}

// ── Section helpers ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
      const Spacer(),
      if (trailing != null) trailing!,
    ],
  );
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.selected, required this.onChanged});
  final AnalyticsPeriod selected;
  final ValueChanged<AnalyticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AnalyticsPeriod>(
      initialValue: selected,
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected.label,
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 14, color: AppTheme.accent),
          ],
        ),
      ),
      itemBuilder: (_) => AnalyticsPeriod.values
          .map((p) => PopupMenuItem(value: p, child: Text(p.label)))
          .toList(),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final option in [null, 'credit', 'debit'])
          ChoiceChip(
            label: Text(option ?? 'All'),
            selected: selected == option,
            onSelected: (_) => onChanged(option),
            selectedColor: AppTheme.accent.withOpacity(0.12),
            labelStyle: TextStyle(
              color: selected == option ? AppTheme.accent : AppTheme.textPrimary,
              fontWeight: selected == option ? FontWeight.w700 : FontWeight.w400,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

class _EmptyLeaderboard extends StatelessWidget {
  const _EmptyLeaderboard();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: Text(
        'No data available',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
    ),
  );
}