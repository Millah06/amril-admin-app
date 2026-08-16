import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../models/config_model.dart';
import '../../providers/config_provider.dart';

/// Dedicated config EDIT page (§3). Preloaded with current values; Save → PATCH
/// /admin/config → pop back to the read-only view. All fields already wired in
/// the model/provider/service are kept.
class ConfigEditScreen extends StatefulWidget {
  const ConfigEditScreen({super.key});

  @override
  State<ConfigEditScreen> createState() => _ConfigEditScreenState();
}

class _ConfigEditScreenState extends State<ConfigEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _txFeeCtrl;
  late final TextEditingController _autoReleaseCtrl;
  late final TextEditingController _appealWindowCtrl;
  late final TextEditingController _chatCloseCtrl;
  late final TextEditingController _commissionCtrl;
  late final TextEditingController _fundingFeesCtrl;
  late final TextEditingController _bonusAirtimeCtrl;
  late final TextEditingController _bonusDataCtrl;
  late final TextEditingController _bonusCableCtrl;
  late final TextEditingController _bonusElectricCtrl;
  late final TextEditingController _withdrawalFeePctCtrl;
  late final TextEditingController _withdrawalFlatCtrl;
  bool _netGatewayFromVendor = true;
  bool _hardwareReservationMode = true;
  bool _brandingAvailable = false;
  // Hardware OTA update (kiosk roadmap Phase 2)
  late final TextEditingController _hwVersionCtrl;
  late final TextEditingController _hwApkUrlCtrl;
  late final TextEditingController _hwShaCtrl;
  late final TextEditingController _hwMinVersionCtrl;
  late final TextEditingController _hwNotesCtrl;
  bool _hwMandatory = false;
  // Consumer app update (Play / App Store prompt)
  late final TextEditingController _auBuildCtrl;
  late final TextEditingController _auVersionCtrl;
  late final TextEditingController _auWhatsNewCtrl;
  late final TextEditingController _auAndroidUrlCtrl;
  late final TextEditingController _auIosUrlCtrl;
  bool _auMandatory = false;
  // Multi-provider payments (Phase 5). Held as one immutable model — switches
  // and dropdowns copyWith into it so save() sends the exact wire shape.
  PaymentsConfigModel _payments = const PaymentsConfigModel();
  // Per-km delivery knobs (delivery roadmap Phase 9). Empty text = no bound.
  late final TextEditingController _dlBaseMinCtrl;
  late final TextEditingController _dlBaseMaxCtrl;
  late final TextEditingController _dlPerKmMinCtrl;
  late final TextEditingController _dlPerKmMaxCtrl;
  late final TextEditingController _dlMaxRadiusCtrl;
  late final TextEditingController _dlRoadFactorCtrl;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _txFeeCtrl = TextEditingController();
    _autoReleaseCtrl = TextEditingController();
    _appealWindowCtrl = TextEditingController();
    _chatCloseCtrl = TextEditingController();
    _commissionCtrl = TextEditingController();
    _fundingFeesCtrl = TextEditingController();
    _bonusAirtimeCtrl = TextEditingController();
    _bonusDataCtrl = TextEditingController();
    _bonusCableCtrl = TextEditingController();
    _bonusElectricCtrl = TextEditingController();
    _withdrawalFeePctCtrl = TextEditingController();
    _withdrawalFlatCtrl = TextEditingController();
    _hwVersionCtrl = TextEditingController();
    _hwApkUrlCtrl = TextEditingController();
    _hwShaCtrl = TextEditingController();
    _hwMinVersionCtrl = TextEditingController();
    _hwNotesCtrl = TextEditingController();
    _auBuildCtrl = TextEditingController();
    _auVersionCtrl = TextEditingController();
    _auWhatsNewCtrl = TextEditingController();
    _auAndroidUrlCtrl = TextEditingController();
    _auIosUrlCtrl = TextEditingController();
    _dlBaseMinCtrl = TextEditingController();
    _dlBaseMaxCtrl = TextEditingController();
    _dlPerKmMinCtrl = TextEditingController();
    _dlPerKmMaxCtrl = TextEditingController();
    _dlMaxRadiusCtrl = TextEditingController();
    _dlRoadFactorCtrl = TextEditingController();

    // The provider was already loaded by the view; populate synchronously if we
    // have it, else load.
    final provider = context.read<ConfigProvider>();
    if (provider.config != null) {
      _populate(provider.config!);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => provider.load());
    }
  }

  @override
  void dispose() {
    for (final c in [
      _txFeeCtrl, _autoReleaseCtrl, _appealWindowCtrl, _chatCloseCtrl,
      _commissionCtrl, _fundingFeesCtrl, _bonusAirtimeCtrl, _bonusDataCtrl,
      _bonusCableCtrl, _bonusElectricCtrl,
      _withdrawalFeePctCtrl, _withdrawalFlatCtrl,
      _hwVersionCtrl, _hwApkUrlCtrl, _hwShaCtrl,
      _hwMinVersionCtrl, _hwNotesCtrl,
      _auBuildCtrl, _auVersionCtrl, _auWhatsNewCtrl,
      _auAndroidUrlCtrl, _auIosUrlCtrl,
      _dlBaseMinCtrl, _dlBaseMaxCtrl, _dlPerKmMinCtrl,
      _dlPerKmMaxCtrl, _dlMaxRadiusCtrl, _dlRoadFactorCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _populate(ConfigModel config) {
    if (_initialized) return;
    _initialized = true;
    _txFeeCtrl.text = config.transactionFeePercent.toString();
    _autoReleaseCtrl.text = config.autoReleaseHours.toString();
    _appealWindowCtrl.text = config.appealWindowHours.toString();
    _chatCloseCtrl.text = config.chatCloseHours.toString();
    _commissionCtrl.text = config.commissionPercent.toString();
    _fundingFeesCtrl.text = config.fundingFees.toString();
    _bonusAirtimeCtrl.text = config.bonusAirtime.toString();
    _bonusDataCtrl.text = config.bonusData.toString();
    _bonusCableCtrl.text = config.bonusCable.toString();
    _bonusElectricCtrl.text = config.bonusElectric.toString();
    _withdrawalFeePctCtrl.text = config.withdrawalFeePercent.toString();
    _withdrawalFlatCtrl.text = config.withdrawalFlatFeeNaira.toString();
    _netGatewayFromVendor = config.netGatewayFromVendor;
    _hardwareReservationMode = config.hardwareReservationMode;
    _brandingAvailable = config.brandingAvailable;
    _payments = config.payments;
    _hwVersionCtrl.text = config.hardwareUpdate.latestVersion;
    _hwApkUrlCtrl.text = config.hardwareUpdate.apkUrl;
    _hwShaCtrl.text = config.hardwareUpdate.sha256;
    _hwMinVersionCtrl.text = config.hardwareUpdate.minSupportedVersion;
    _hwNotesCtrl.text = config.hardwareUpdate.notes;
    _hwMandatory = config.hardwareUpdate.mandatory;
    _auBuildCtrl.text =
        config.appUpdate.isPublished ? config.appUpdate.latestBuild.toString() : '';
    _auVersionCtrl.text = config.appUpdate.versionName;
    _auWhatsNewCtrl.text = config.appUpdate.whatsNew.join('\n');
    _auAndroidUrlCtrl.text = config.appUpdate.androidUrl;
    _auIosUrlCtrl.text = config.appUpdate.iosUrl;
    _auMandatory = config.appUpdate.mandatory;
    String dl(double? v) => v == null
        ? ''
        : (v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toString());
    _dlBaseMinCtrl.text = dl(config.delivery.baseFeeMin);
    _dlBaseMaxCtrl.text = dl(config.delivery.baseFeeMax);
    _dlPerKmMinCtrl.text = dl(config.delivery.perKmMin);
    _dlPerKmMaxCtrl.text = dl(config.delivery.perKmMax);
    _dlMaxRadiusCtrl.text = dl(config.delivery.maxRadiusKm);
    _dlRoadFactorCtrl.text = dl(config.delivery.roadFactor);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    // Hardware update block: publishing (non-empty version) needs a URL + a
    // real SHA-256; an empty version clears the published update (API stores
    // null). Mirrors the API-side validation so admins get instant feedback.
    final hw = HardwareUpdateModel(
      latestVersion: _hwVersionCtrl.text.trim(),
      apkUrl: _hwApkUrlCtrl.text.trim(),
      sha256: _hwShaCtrl.text.trim().toLowerCase(),
      mandatory: _hwMandatory,
      minSupportedVersion: _hwMinVersionCtrl.text.trim(),
      notes: _hwNotesCtrl.text.trim(),
    );
    if (hw.isPublished &&
        (hw.apkUrl.isEmpty || !RegExp(r'^[0-9a-f]{64}$').hasMatch(hw.sha256))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Hardware update needs an APK URL and a 64-char SHA-256 hash.'),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Consumer app-update block: publishing needs a build number + version
    // name; an empty build number clears it (API stores null).
    final au = AppUpdateModel(
      latestBuild: int.tryParse(_auBuildCtrl.text.trim()) ?? 0,
      versionName: _auVersionCtrl.text.trim(),
      whatsNew: _auWhatsNewCtrl.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      mandatory: _auMandatory,
      androidUrl: _auAndroidUrlCtrl.text.trim(),
      iosUrl: _auIosUrlCtrl.text.trim(),
    );
    if (au.isPublished && au.versionName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('App update needs a version name (e.g. 1.5.0).'),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Per-km delivery knobs: min ≤ max validated here for instant feedback
    // (API re-validates). Empty field = no bound / API default.
    double? dl(TextEditingController c) {
      final t = c.text.trim();
      if (t.isEmpty) return null;
      return double.tryParse(t);
    }

    final delivery = DeliveryConfigModel(
      baseFeeMin: dl(_dlBaseMinCtrl),
      baseFeeMax: dl(_dlBaseMaxCtrl),
      perKmMin: dl(_dlPerKmMinCtrl),
      perKmMax: dl(_dlPerKmMaxCtrl),
      maxRadiusKm: dl(_dlMaxRadiusCtrl),
      roadFactor: dl(_dlRoadFactorCtrl),
    );
    if ((delivery.baseFeeMin != null &&
            delivery.baseFeeMax != null &&
            delivery.baseFeeMin! > delivery.baseFeeMax!) ||
        (delivery.perKmMin != null &&
            delivery.perKmMax != null &&
            delivery.perKmMin! > delivery.perKmMax!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Delivery range min cannot exceed max.'),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (delivery.roadFactor != null &&
        (delivery.roadFactor! < 1 || delivery.roadFactor! > 3)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Road factor must be between 1 and 3 (default 1.3).'),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final err = await context.read<ConfigProvider>().save({
      'transactionFeePercent': double.parse(_txFeeCtrl.text),
      'autoReleaseHours': int.parse(_autoReleaseCtrl.text),
      'appealWindowHours': int.parse(_appealWindowCtrl.text),
      'chatCloseHours': double.parse(_chatCloseCtrl.text),
      'commissionPercent': double.parse(_commissionCtrl.text),
      'fundingFees': double.parse(_fundingFeesCtrl.text),
      'bonusAirtime': double.parse(_bonusAirtimeCtrl.text),
      'bonusData': double.parse(_bonusDataCtrl.text),
      'bonusCable': double.parse(_bonusCableCtrl.text),
      'bonusElectric': double.parse(_bonusElectricCtrl.text),
      'withdrawalFeePercent': double.parse(_withdrawalFeePctCtrl.text),
      'withdrawalFlatFeeNaira': double.parse(_withdrawalFlatCtrl.text),
      'netGatewayFromVendor': _netGatewayFromVendor,
      'hardwareReservationMode': _hardwareReservationMode,
      'brandingAvailable': _brandingAvailable,
      'payments': _payments.toJson(),
      'hardwareUpdate': hw.toJson(),
      'appUpdate': au.toJson(),
      'delivery': delivery.toJson(),
    });

    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Config saved ✓'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Config')),
      body: Consumer<ConfigProvider>(
        builder: (_, provider, __) {
          if (provider.loading && provider.config == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.config == null) {
            return ErrorView(
              message: provider.error!,
              onRetry: () {
                _initialized = false;
                provider.load();
              },
            );
          }
          if (provider.config != null) _populate(provider.config!);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                _group(
                  'Financials',
                  Icons.account_balance_outlined,
                  [
                    _field(_txFeeCtrl, 'Transaction Fee (%)',
                        hint: 'e.g. 1.5', suffix: '%', isDecimal: true),
                    _field(_commissionCtrl, 'Commission (%)',
                        hint: 'locked rate is 3', suffix: '%', isDecimal: true),
                    _field(_fundingFeesCtrl, 'Funding Fees (₦)',
                        hint: 'e.g. 0', prefix: '₦', isDecimal: true),
                  ],
                ),
                _group(
                  'Timings',
                  Icons.schedule_rounded,
                  [
                    _field(_autoReleaseCtrl, 'Auto Release (hours)',
                        hint: 'e.g. 24', suffix: 'hrs'),
                    _field(_appealWindowCtrl, 'Appeal Window (hours)',
                        hint: 'e.g. 48', suffix: 'hrs'),
                    _field(_chatCloseCtrl, 'Chat Close (hours)',
                        hint: 'e.g. 72', suffix: 'hrs'),
                  ],
                ),
                _group(
                  'Utility Bonuses (%)',
                  Icons.bolt_rounded,
                  [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Cashback % given to users on each utility purchase.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                    _field(_bonusAirtimeCtrl, 'Airtime',
                        suffix: '%', isDecimal: true),
                    _field(_bonusDataCtrl, 'Data', suffix: '%', isDecimal: true),
                    _field(_bonusCableCtrl, 'Cable TV',
                        suffix: '%', isDecimal: true),
                    _field(_bonusElectricCtrl, 'Electricity',
                        suffix: '%', isDecimal: true),
                  ],
                ),
                _group(
                  'Vendor Fees & Settlement',
                  Icons.request_quote_outlined,
                  [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Customers pay the exact price — costs are recovered on '
                        'the vendor side. Applied on payouts.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                    _field(_withdrawalFeePctCtrl, 'Withdrawal Fee (%)',
                        hint: 'e.g. 1', suffix: '%', isDecimal: true),
                    _field(_withdrawalFlatCtrl, 'Withdrawal Flat Fee (₦)',
                        hint: 'e.g. 50', prefix: '₦'),
                    _switch(
                      'Net gateway fee from vendor',
                      'Card/online orders only. Off = Amril absorbs processing (promo).',
                      _netGatewayFromVendor,
                      (v) => setState(() => _netGatewayFromVendor = v),
                    ),
                  ],
                ),
                _group(
                  'Hardware Program',
                  Icons.point_of_sale_outlined,
                  [
                    _switch(
                      'Reservation mode',
                      'On = vendors reserve with no payment (waitlist). Off = charge on order.',
                      _hardwareReservationMode,
                      (v) => setState(() => _hardwareReservationMode = v),
                    ),
                    _switch(
                      'Co-branding available',
                      'Turn on once an OEM can silkscreen vendor logos.',
                      _brandingAvailable,
                      (v) => setState(() => _brandingAvailable = v),
                    ),
                  ],
                ),
                _group(
                  'Hardware Update (OTA)',
                  Icons.system_update_alt_rounded,
                  [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Self-update for KDS/CDS/kiosk devices (Play Store never '
                        'updates them). Upload the versioned APK to the R2 '
                        '"hardware/" folder first, then publish its URL + hash '
                        'here. Clear the version to unpublish.\n'
                        'Compute the hash on Windows with:  Get-FileHash '
                        '-Algorithm SHA256 .\\amril-hw-x.y.z.apk',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                    _textField(_hwVersionCtrl, 'Latest version',
                        hint: 'e.g. 1.4.2 (empty = nothing published)'),
                    _textField(_hwApkUrlCtrl, 'APK URL',
                        hint: 'https://…/hardware/amril-hw-1.4.2.apk'),
                    _textField(_hwShaCtrl, 'SHA-256',
                        hint: '64 hex characters'),
                    _textField(_hwMinVersionCtrl, 'Min supported version',
                        hint: 'devices below this are force-updated (optional)'),
                    _textField(_hwNotesCtrl, 'Notes',
                        hint: 'shown on the device update card (optional)'),
                    _switch(
                      'Mandatory',
                      'Devices block their display until this update installs. '
                      'Use for breaking API changes only.',
                      _hwMandatory,
                      (v) => setState(() => _hwMandatory = v),
                    ),
                  ],
                ),
                _group(
                  'App Update (Play / App Store)',
                  Icons.storefront_rounded,
                  [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Prompts consumer apps to update from their store. '
                        'Build number = the versionCode you shipped (pubspec '
                        'version after the "+"). Clear it to unpublish. '
                        'Mandatory blocks the app until updated — use only for '
                        'breaking API changes. Leave the iOS URL empty until '
                        'the App Store listing exists (iPhones are then never '
                        'prompted).',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                    _field(_auBuildCtrl, 'Latest build number',
                        hint: 'e.g. 42 (empty = nothing published)',
                        required: false),
                    _textField(_auVersionCtrl, 'Version name',
                        hint: 'e.g. 1.5.0 — shown in the prompt'),
                    _textField(_auWhatsNewCtrl, 'What\'s new',
                        hint: 'one feature per line', maxLines: 4),
                    _textField(_auAndroidUrlCtrl, 'Android store URL',
                        hint:
                            'https://play.google.com/store/apps/details?id=com.amril.app'),
                    _textField(_auIosUrlCtrl, 'iOS store URL',
                        hint: 'empty until the App Store listing is live'),
                    _switch(
                      'Mandatory',
                      'App blocks until updated. Breaking changes only.',
                      _auMandatory,
                      (v) => setState(() => _auMandatory = v),
                    ),
                  ],
                ),
                _group(
                  'Payments — Collection',
                  Icons.credit_card_rounded,
                  [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Which payment methods the app offers at checkout. '
                        'Changes apply on the next config fetch — no redeploy.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                    _switch(
                      'Wallet',
                      'In-app wallet balance as a payment method.',
                      _payments.walletEnabled,
                      (v) => setState(() =>
                          _payments = _payments.copyWith(walletEnabled: v)),
                    ),
                    _switch(
                      'Paystack (Card / Bank)',
                      'Hosted checkout via Paystack.',
                      _payments.paystackEnabled,
                      (v) => setState(() =>
                          _payments = _payments.copyWith(paystackEnabled: v)),
                    ),
                    _switch(
                      'Monnify (Card / Bank)',
                      'Hosted checkout via Monnify. Verify in sandbox before enabling.',
                      _payments.monnifyEnabled,
                      (v) => setState(() =>
                          _payments = _payments.copyWith(monnifyEnabled: v)),
                    ),
                    _switch(
                      'OPay',
                      'The OPay flip — turn on the day OPay approves the live account. '
                      'Off hides "Pay with OPay" in the app.',
                      _payments.opayEnabled,
                      (v) => setState(() =>
                          _payments = _payments.copyWith(opayEnabled: v)),
                    ),
                    _dropdown(
                      'Online primary',
                      'Provider behind the app\'s smart "Card / Bank" row.',
                      _payments.onlinePrimary,
                      const {
                        'paystack': 'Paystack',
                        'monnify': 'Monnify',
                        'opay': 'OPay',
                      },
                      (v) => setState(() =>
                          _payments = _payments.copyWith(onlinePrimary: v)),
                    ),
                    if (!_onlinePrimaryEnabled)
                      _warnNote(
                          'The selected online primary is currently disabled above — '
                          'the app will fall back to its safe default.'),
                  ],
                ),
                _group(
                  'Payments — Withdrawal & KYC',
                  Icons.outbound_rounded,
                  [
                    _dropdown(
                      'Withdrawal primary',
                      'Payout provider tried first. Monnify/Flutterwave need the '
                      'proxy IP whitelisted + live activation before flipping.',
                      _payments.withdrawalPrimary,
                      const {
                        'paystack': 'Paystack',
                        'flutterwave': 'Flutterwave',
                        'monnify': 'Monnify',
                        'opay': 'OPay',
                      },
                      (v) => setState(() =>
                          _payments = _payments.copyWith(withdrawalPrimary: v)),
                    ),
                    _switch(
                      'Automatic failover',
                      'If the primary hard-fails, retry on the next configured '
                      'provider (same reference — no double-pay).',
                      _payments.failoverEnabled,
                      (v) => setState(() =>
                          _payments = _payments.copyWith(failoverEnabled: v)),
                    ),
                    _dropdown(
                      'KYC provider',
                      'BVN/NIN name-match lookups. Monnify is live-only and '
                      'charged from the Monnify wallet.',
                      _payments.kycProvider,
                      const {'monnify': 'Monnify', 'dojah': 'Dojah'},
                      (v) => setState(() =>
                          _payments = _payments.copyWith(kycProvider: v)),
                    ),
                    _switch(
                      'Paystack virtual accounts',
                      'Dedicated funding account numbers for all users.',
                      _payments.vaPaystack,
                      (v) => setState(() =>
                          _payments = _payments.copyWith(vaPaystack: v)),
                    ),
                  ],
                ),
                _group(
                  'Delivery (per-km)',
                  Icons.delivery_dining_rounded,
                  [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Global bounds for vendor delivery pricing (fee = base '
                        '+ rate × road km, rounded up to ₦50). Empty = no '
                        'bound. Ranges clamp out-of-range vendor rates at '
                        'quote time — edit here when petrol moves, no '
                        'migration needed.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                    _field(_dlBaseMinCtrl, 'Base fee min (₦)',
                        hint: 'empty = open', prefix: '₦',
                        isDecimal: true, required: false),
                    _field(_dlBaseMaxCtrl, 'Base fee max (₦)',
                        hint: 'empty = open', prefix: '₦',
                        isDecimal: true, required: false),
                    _field(_dlPerKmMinCtrl, 'Per-km min (₦)',
                        hint: 'empty = open', prefix: '₦',
                        isDecimal: true, required: false),
                    _field(_dlPerKmMaxCtrl, 'Per-km max (₦)',
                        hint: 'empty = open', prefix: '₦',
                        isDecimal: true, required: false),
                    _field(_dlMaxRadiusCtrl, 'Max radius cap (km)',
                        hint: 'empty = default 30', suffix: 'km',
                        isDecimal: true, required: false),
                    _field(_dlRoadFactorCtrl, 'Road factor',
                        hint: 'empty = default 1.3 (straight-line × factor)',
                        isDecimal: true, required: false),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: Consumer<ConfigProvider>(
              builder: (_, p, __) => ElevatedButton.icon(
                onPressed: p.saving ? null : _save,
                icon: p.saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(p.saving ? 'Saving…' : 'Save Changes'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──

  /// True when the provider picked as onlinePrimary is also enabled above.
  bool get _onlinePrimaryEnabled {
    switch (_payments.onlinePrimary) {
      case 'paystack':
        return _payments.paystackEnabled;
      case 'monnify':
        return _payments.monnifyEnabled;
      case 'opay':
        return _payments.opayEnabled;
      default:
        return false;
    }
  }

  Widget _dropdown(
    String label,
    String subtitle,
    String value,
    Map<String, String> options,
    ValueChanged<String> onChanged,
  ) {
    // Guard against a stored value not in the options (shouldn't happen — the
    // API validates — but a dropdown crashes hard on an unknown value).
    final safeValue = options.containsKey(value) ? value : options.keys.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 8),
            child: Text(subtitle,
                style: const TextStyle(
                    fontSize: 11.5, color: AppTheme.textSecondary)),
          ),
          DropdownButtonFormField<String>(
            // Keyed by value so a late _populate (config fetched after first
            // build) re-syncs the field — initialValue alone is read once.
            key: ValueKey('$label:$safeValue'),
            initialValue: safeValue,
            decoration: const InputDecoration(isDense: true),
            dropdownColor: AppTheme.surface,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            items: options.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _warnNote(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 14, color: AppTheme.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(color: AppTheme.warning, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  Widget _group(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    String? suffix,
    String? prefix,
    bool isDecimal = false,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: AppTheme.textPrimary),
        keyboardType: isDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: suffix,
          prefixText: prefix,
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return required ? 'Required' : null;
          final n = num.tryParse(v);
          if (n == null) return 'Enter a valid number';
          if (n < 0) return 'Cannot be negative';
          return null;
        },
      ),
    );
  }

  /// Free-text field (no numeric validation) — all hardware-update fields are
  /// optional at the field level; cross-field rules are enforced in _save.
  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  Widget _switch(
    String label,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppTheme.textSecondary)),
                ),
              ],
            ),
          ),
          Switch(
              value: value,
              activeThumbColor: AppTheme.primary,
              onChanged: onChanged),
        ],
      ),
    );
  }
}
