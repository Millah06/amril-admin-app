import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../models/config_model.dart';
import '../../providers/config_provider.dart';
import 'config_edit_screen.dart';

/// Read-only config view (§3). Shows every config value in a clean, grouped,
/// labelled layout. "Edit" (top-right) opens [ConfigEditScreen] preloaded.
class ConfigViewScreen extends StatefulWidget {
  const ConfigViewScreen({super.key});

  @override
  State<ConfigViewScreen> createState() => _ConfigViewScreenState();
}

class _ConfigViewScreenState extends State<ConfigViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<ConfigProvider>().load());
  }

  Future<void> _openEdit() async {
    final provider = context.read<ConfigProvider>();
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const ConfigEditScreen(),
    ),),
    );
    if (saved == true && mounted) {
      context.read<ConfigProvider>().load(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Config'),
        actions: [
          Consumer<ConfigProvider>(
            builder: (_, p, __) => TextButton.icon(
              onPressed: p.config == null ? null : _openEdit,
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppTheme.primary),
              label: const Text('Edit',
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Consumer<ConfigProvider>(
        builder: (_, provider, __) {
          if (provider.loading && provider.config == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.config == null) {
            return ErrorView(
              message: provider.error!,
              onRetry: () => provider.load(),
            );
          }
          final c = provider.config;
          if (c == null) {
            return const Center(
              child: Text('No config loaded',
                  style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.load(silent: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _hero(c),
                const SizedBox(height: 16),
                _group('Financials', Icons.account_balance_outlined, [
                  _row('Transaction Fee', '${c.transactionFeePercent}%'),
                  _commissionRow(c),
                  _row('Funding Fees', '₦${c.fundingFees}'),
                ]),
                _group('Timings', Icons.schedule_rounded, [
                  _row('Auto Release', '${c.autoReleaseHours} hrs'),
                  _row('Appeal Window', '${c.appealWindowHours} hrs'),
                  _row('Chat Close', '${c.chatCloseHours} hrs'),
                ]),
                _group('Utility Bonuses', Icons.bolt_rounded, [
                  _row('Airtime', '${c.bonusAirtime}%'),
                  _row('Data', '${c.bonusData}%'),
                  _row('Cable TV', '${c.bonusCable}%'),
                  _row('Electricity', '${c.bonusElectric}%'),
                ]),
                _group('Vendor Fees & Settlement', Icons.request_quote_outlined,
                    [
                      _row('Withdrawal Fee', '${c.withdrawalFeePercent}%'),
                      _row('Withdrawal Flat Fee', '₦${c.withdrawalFlatFeeNaira}'),
                      _boolRow('Net gateway fee from vendor',
                          c.netGatewayFromVendor),
                    ]),
                _group('Hardware Program', Icons.point_of_sale_outlined, [
                  _boolRow('Reservation mode', c.hardwareReservationMode),
                  _boolRow('Co-branding available', c.brandingAvailable),
                ]),
                _group('Hardware Update (OTA)', Icons.system_update_alt_rounded, [
                  if (!c.hardwareUpdate.isPublished)
                    _row('Published update', 'None')
                  else ...[
                    _row('Latest version', c.hardwareUpdate.latestVersion),
                    _row(
                        'Min supported',
                        c.hardwareUpdate.minSupportedVersion.isEmpty
                            ? '—'
                            : c.hardwareUpdate.minSupportedVersion),
                    _boolRow('Mandatory', c.hardwareUpdate.mandatory),
                    _row('SHA-256',
                        '${c.hardwareUpdate.sha256.length > 12 ? c.hardwareUpdate.sha256.substring(0, 12) : c.hardwareUpdate.sha256}…'),
                  ],
                ]),
                _group('App Update (Play / App Store)', Icons.storefront_rounded, [
                  if (!c.appUpdate.isPublished)
                    _row('Published update', 'None')
                  else ...[
                    _row('Latest build',
                        '${c.appUpdate.latestBuild} (v${c.appUpdate.versionName})'),
                    _boolRow('Mandatory', c.appUpdate.mandatory),
                    _row('What\'s new', '${c.appUpdate.whatsNew.length} item(s)'),
                    _boolRow('Android URL set', c.appUpdate.androidUrl.isNotEmpty),
                    _boolRow('iOS URL set', c.appUpdate.iosUrl.isNotEmpty),
                  ],
                ]),
                _group('Payments — Collection', Icons.credit_card_rounded, [
                  _boolRow('Wallet', c.payments.walletEnabled),
                  _boolRow('Paystack (Card / Bank)', c.payments.paystackEnabled),
                  _boolRow('Monnify (Card / Bank)', c.payments.monnifyEnabled),
                  _boolRow('OPay', c.payments.opayEnabled),
                  _row('Online primary', _providerName(c.payments.onlinePrimary)),
                ]),
                _group('Payments — Withdrawal & KYC', Icons.outbound_rounded, [
                  _row('Withdrawal primary',
                      _providerName(c.payments.withdrawalPrimary)),
                  _boolRow('Automatic failover', c.payments.failoverEnabled),
                  _row('KYC provider', _providerName(c.payments.kycProvider)),
                  _boolRow('Paystack virtual accounts', c.payments.vaPaystack),
                ]),
                _group('Delivery (per-km)', Icons.delivery_dining_rounded, [
                  _row('Base fee range', _range(c.delivery.baseFeeMin, c.delivery.baseFeeMax, '₦')),
                  _row('Per-km range', _range(c.delivery.perKmMin, c.delivery.perKmMax, '₦')),
                  _row('Max radius',
                      c.delivery.maxRadiusKm == null
                          ? 'Default (30 km)'
                          : '${_num(c.delivery.maxRadiusKm!)} km'),
                  _row('Road factor',
                      c.delivery.roadFactor == null
                          ? 'Default (1.3)'
                          : _num(c.delivery.roadFactor!)),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Config'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Trim trailing ".0" so ranges read "₦50", not "₦50.0".
  String _num(double v) =>
      v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toString();

  // "₦0 – ₦1,000" style range; missing ends read as open.
  String _range(double? min, double? max, String unit) {
    if (min == null && max == null) return 'Unbounded (vendor free)';
    final lo = min == null ? 'Open' : '$unit${_num(min)}';
    final hi = max == null ? 'open' : '$unit${_num(max)}';
    return '$lo – $hi';
  }

  // Pretty display name for a provider key stored in AppConfig.payments.
  String _providerName(String key) {
    switch (key) {
      case 'paystack':
        return 'Paystack';
      case 'monnify':
        return 'Monnify';
      case 'flutterwave':
        return 'Flutterwave';
      case 'opay':
        return 'OPay';
      case 'dojah':
        return 'Dojah';
      default:
        return key;
    }
  }

  // ── Hero card ──
  Widget _hero(ConfigModel c) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.18),
            AppTheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune_rounded,
                color: AppTheme.primary, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Platform Configuration',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                SizedBox(height: 4),
                Text('Read-only. Tap Edit to change any value.',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Commission row with the locked-rate reminder (§3) ──
  Widget _commissionRow(ConfigModel c) {
    final isThree = c.commissionPercent == 3;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Commission',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5)),
              Text('${c.commissionPercent}%',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
          if (!isThree)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 13, color: AppTheme.warning),
                  const SizedBox(width: 5),
                  Text('Roadmap locked rate is 3% — currently ${c.commissionPercent}%.',
                      style: const TextStyle(
                          color: AppTheme.warning, fontSize: 11.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Grouped card ──
  Widget _group(String title, IconData icon, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: AppTheme.divider, height: 14),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13.5)),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _boolRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13.5)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: (value ? AppTheme.success : AppTheme.textSecondary)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(value ? 'ON' : 'OFF',
                style: TextStyle(
                    color: value ? AppTheme.success : AppTheme.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
