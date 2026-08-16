// REPO PATH: lib/features/reconciliation/screen.dart   (NEW FILE — admin_panel)
//
// Treasury / reconciliation surface. Two solvency cards over one design:
//   • Track A — NGN wallet float  (Paystack + OPay  vs  user+merchant liabilities)
//   • Track B — Coin treasury     (coin proceeds + IAP store payouts  vs  NG
//                                  earned-coin cash-out liability)
// Plus an inputs card for the externally-known balances the server can't fetch
// (OPay, Apple App Store, Google Play), a "Recompute" preview and a "Save
// snapshot" persist action.
//
// Self-provides its provider so it can be dropped straight into ShellScreen's
// tab list with no app.dart wiring.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_grid.dart';
import 'model.dart';
import 'provider.dart';
import 'service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Local formatters (kept here to avoid coupling to a specific formatters export).
// ─────────────────────────────────────────────────────────────────────────────
String _grouped(num v) {
  final neg = v < 0;
  final s = v.abs().round().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${neg ? '-' : ''}$buf';
}

String _naira(num v) => '₦${_grouped(v)}';
String _coins(int v) => '${_grouped(v)} coins';

// ─────────────────────────────────────────────────────────────────────────────
class TreasuryScreen extends StatelessWidget {
  const TreasuryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider is scoped to this screen and loads immediately on creation.
    return ChangeNotifierProvider(
      create: (_) => TreasuryProvider(TreasuryService())..load(),
      child: const _TreasuryView(),
    );
  }
}

class _TreasuryView extends StatefulWidget {
  const _TreasuryView();

  @override
  State<_TreasuryView> createState() => _TreasuryViewState();
}

class _TreasuryViewState extends State<_TreasuryView> {
  final _opay = TextEditingController();
  final _monnify = TextEditingController();
  final _bank = TextEditingController();
  final _vtpass = TextEditingController();
  final _apple = TextEditingController();
  final _google = TextEditingController();

  @override
  void dispose() {
    _opay.dispose();
    _monnify.dispose();
    _bank.dispose();
    _vtpass.dispose();
    _apple.dispose();
    _google.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treasury'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recompute',
            onPressed: () => context.read<TreasuryProvider>().load(),
          ),
        ],
      ),
      body: Consumer<TreasuryProvider>(
        builder: (_, p, __) {
          if (p.loading) return const LoadingGrid();
          if (p.error != null) {
            return ErrorView(message: p.error!, onRetry: () => p.load());
          }
          final s = p.summary;
          if (s == null) return ErrorView(message: 'No data', onRetry: () => p.load());

          return RefreshIndicator(
            onRefresh: () => p.load(silent: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _takenAt(s.takenAt),
                const SizedBox(height: 12),

                // ── Track A: NGN wallet float ──────────────────────────────
                _TrackCard(
                  title: 'NGN Wallet Float',
                  subtitle: 'Real Naira held across the PSPs (Paystack, OPay, Monnify)',
                  status: s.ngn.status,
                  liabilityRows: [
                    _Row('User available', _naira(s.ngn.userAvailable)),
                    _Row('User locked (in-flight)', _naira(s.ngn.userLocked)),
                    _Row('Merchant pending', _naira(s.ngn.merchantPending)),
                  ],
                  liabilityTotal: _Row('Total owed', _naira(s.ngn.liabilities), strong: true),
                  floatRows: [
                    _Row(
                      'Paystack',
                      _naira(s.ngn.paystackBalance),
                      tag: s.ngn.paystackFetchOk ? 'live' : 'manual',
                      tagColor: s.ngn.paystackFetchOk ? AppTheme.success : AppTheme.warning,
                    ),
                    _Row('OPay', _naira(s.ngn.opayBalance), muted: s.ngn.opayBalance == 0),
                    _Row(
                      'Monnify',
                      _naira(s.ngn.monnifyBalance),
                      tag: s.ngn.monnifyFetchOk ? 'live' : 'manual',
                      tagColor: s.ngn.monnifyFetchOk ? AppTheme.success : AppTheme.warning,
                      muted: !s.ngn.monnifyFetchOk && s.ngn.monnifyBalance == 0,
                    ),
                    _Row('Bank (settlement)', _naira(s.ngn.bankBalance), muted: s.ngn.bankBalance == 0),
                    _Row('VTPass prepaid', _naira(s.ngn.vtpassBalance), muted: s.ngn.vtpassBalance == 0),
                  ],
                  floatTotal: _Row('Total held', _naira(s.ngn.float), strong: true),
                  surplusLabel: 'Surplus (cushion)',
                  surplus: s.ngn.surplus,
                  footnotes: [
                    'Unswept NGN revenue (lifetime): ${_naira(s.ngn.revenueTotal)}',
                    if (!s.ngn.paystackFetchOk && s.ngn.paystackReason.isNotEmpty)
                      'Paystack not auto-fetched: ${s.ngn.paystackReason}',
                    if (!s.ngn.monnifyFetchOk && s.ngn.monnifyReason.isNotEmpty)
                      'Monnify not auto-fetched: ${s.ngn.monnifyReason}',
                  ],
                ),
                const SizedBox(height: 16),

                // ── Track B: coin treasury ─────────────────────────────────
                _TrackCard(
                  title: 'Coin Treasury',
                  subtitle: 'Separate cash-out rail — funded by coin sales, never the wallet float',
                  status: s.coin.status,
                  liabilityRows: [
                    _Row('NG earned coins', _coins(s.coin.ngEarnedCoins)),
                    _Row('× conversion rate (₦${_grouped(s.coin.conversionRate)})',
                        _naira(s.coin.coinLiability)),
                  ],
                  liabilityTotal: _Row('Cash-out obligation', _naira(s.coin.coinLiability), strong: true),
                  floatRows: [
                    _Row('NG coin proceeds', _naira(s.coin.coinPurchaseProceedsNg),
                        tag: 'earmarked', tagColor: AppTheme.textSecondary),
                    _Row('Apple App Store', _naira(s.coin.appleBalance), muted: s.coin.appleBalance == 0),
                    _Row('Google Play', _naira(s.coin.googleBalance), muted: s.coin.googleBalance == 0),
                    _Row('− conversions paid', _naira(-s.coin.conversionsPaid)),
                  ],
                  floatTotal: _Row('Coin funding', _naira(s.coin.funding), strong: true),
                  surplusLabel: 'Coin surplus',
                  surplus: s.coin.surplus,
                  footnotes: [
                    'Coin revenue (lifetime): ${_naira(s.coin.revenueTotal)}',
                    'Non-NG earned (info, never converts): ${_coins(s.coin.nonNgEarnedCoins)}',
                    'Purchased outstanding (deferred): ${_coins(s.coin.purchasedOutstanding)}',
                  ],
                ),
                const SizedBox(height: 16),

                // ── Inputs the server can't fetch ──────────────────────────
                _inputsCard(context, p),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _takenAt(String iso) {
    final t = DateTime.tryParse(iso)?.toLocal();
    final txt = t == null
        ? iso
        : '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Row(
      children: [
        const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text('Computed $txt',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  // Manual balance entry + actions.
  Widget _inputsCard(BuildContext context, TreasuryProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('External balances',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Paystack and Monnify are fetched automatically (creds permitting). '
              'Enter the others from their dashboards; a Monnify entry overrides the live fetch.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 14),
          _balanceField('OPay balance (₦)', _opay, p.setOpay),
          const SizedBox(height: 10),
          _balanceField('Monnify override (₦) — blank = auto-fetch', _monnify, p.setMonnify),
          const SizedBox(height: 10),
          _balanceField('Bank — settlement account (₦)', _bank, p.setBank),
          const SizedBox(height: 10),
          _balanceField('VTPass — prepaid wallet (₦)', _vtpass, p.setVtpass),
          const SizedBox(height: 10),
          _balanceField('Apple — App Store Connect pending (₦)', _apple, p.setApple),
          const SizedBox(height: 10),
          _balanceField('Google — Play Console pending (₦)', _google, p.setGoogle),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: p.saving ? null : () => p.load(),
                  icon: const Icon(Icons.calculate_rounded, size: 18),
                  label: const Text('Recompute'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: p.saving
                      ? null
                      : () async {
                    await p.saveSnapshot();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(p.saveMessage ?? 'Done')),
                    );
                  },
                  icon: p.saving
                      ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save snapshot'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceField(String label, TextEditingController c, void Function(String) onChanged) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A single solvency card: liabilities block, float/funding block, surplus banner.
// ─────────────────────────────────────────────────────────────────────────────
class _TrackCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final ReconStatus status;
  final List<_Row> liabilityRows;
  final _Row liabilityTotal;
  final List<_Row> floatRows;
  final _Row floatTotal;
  final String surplusLabel;
  final double surplus;
  final List<String> footnotes;

  const _TrackCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.liabilityRows,
    required this.liabilityTotal,
    required this.floatRows,
    required this.floatTotal,
    required this.surplusLabel,
    required this.surplus,
    required this.footnotes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                _StatusChip(status),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),

          // Liabilities
          _section('Owe', liabilityRows, liabilityTotal),
          const Divider(height: 1, color: AppTheme.divider),
          // Float / funding
          _section('Hold', floatRows, floatTotal),

          // Surplus banner
          _surplusBanner(),

          // Footnotes
          if (footnotes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: footnotes
                    .map((f) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• $f',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5)),
                ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _section(String heading, List<_Row> rows, _Row total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading.toUpperCase(),
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          ...rows.map((r) => r.build()),
          const SizedBox(height: 6),
          total.build(),
        ],
      ),
    );
  }

  Widget _surplusBanner() {
    final positive = surplus >= 0;
    final c = positive ? AppTheme.success : AppTheme.danger;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(positive ? Icons.verified_rounded : Icons.warning_amber_rounded, color: c, size: 18),
          const SizedBox(width: 8),
          Text(surplusLabel,
              style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 13)),
          const Spacer(),
          Text(_naira(surplus),
              style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }
}

// A label/value row spec (built lazily so the card can compose them).
class _Row {
  final String label;
  final String value;
  final bool strong;
  final bool muted;
  final String? tag;
  final Color? tagColor;

  const _Row(this.label, this.value, {this.strong = false, this.muted = false, this.tag, this.tagColor});

  Widget build() {
    final labelColor = muted ? AppTheme.textSecondary : AppTheme.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(label,
                      style: TextStyle(
                          color: strong ? AppTheme.textPrimary : labelColor,
                          fontSize: 13,
                          fontWeight: strong ? FontWeight.w700 : FontWeight.w400)),
                ),
                if (tag != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: (tagColor ?? AppTheme.textSecondary).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(tag!,
                        style: TextStyle(
                            color: tagColor ?? AppTheme.textSecondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
          Text(value,
              style: TextStyle(
                  color: strong ? AppTheme.textPrimary : labelColor,
                  fontSize: 13.5,
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ReconStatus status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    late Color c;
    late String label;
    switch (status) {
      case ReconStatus.ok:
        c = AppTheme.success;
        label = 'Healthy';
        break;
      case ReconStatus.warn:
        c = AppTheme.warning;
        label = 'Thin cushion';
        break;
      case ReconStatus.breach:
        c = AppTheme.danger;
        label = 'BREACH';
        break;
      default:
        c = AppTheme.textSecondary;
        label = '—';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}