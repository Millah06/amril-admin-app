import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/error_view.dart';
import '../models/config_model.dart';
import '../providers/config_provider.dart';

class ConfigTab extends StatefulWidget {
  const ConfigTab({super.key});

  @override
  State<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends State<ConfigTab> {
  final _formKey = GlobalKey<FormState>();

  // Controllers — all as strings for TextField input
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConfigProvider>().load();
    });
  }

  @override
  void dispose() {
    for (final c in [
      _txFeeCtrl, _autoReleaseCtrl, _appealWindowCtrl, _chatCloseCtrl,
      _commissionCtrl, _fundingFeesCtrl, _bonusAirtimeCtrl, _bonusDataCtrl,
      _bonusCableCtrl, _bonusElectricCtrl,
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
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final err = await context.read<ConfigProvider>().save({
      'transactionFeePercent': double.parse(_txFeeCtrl.text),
      'autoReleaseHours': int.parse(_autoReleaseCtrl.text),
      'appealWindowHours': int.parse(_appealWindowCtrl.text),
      'chatCloseHours': int.parse(_chatCloseCtrl.text),
      'commissionPercent': double.parse(_commissionCtrl.text),
      'fundingFees': double.parse(_fundingFeesCtrl.text),
      'bonusAirtime': double.parse(_bonusAirtimeCtrl.text),
      'bonusData': double.parse(_bonusDataCtrl.text),
      'bonusCable': double.parse(_bonusCableCtrl.text),
      'bonusElectric': double.parse(_bonusElectricCtrl.text),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'Config saved ✓'),
      backgroundColor: err != null ? AppTheme.danger : AppTheme.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Config'),
        actions: [
          Consumer<ConfigProvider>(
            builder: (_, p, __) => TextButton(
              onPressed: p.saving ? null : _save,
              child: p.saving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.accent),
              )
                  : const Text('Save',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent)),
            ),
          ),
        ],
      ),
      body: Consumer<ConfigProvider>(
        builder: (_, provider, __) {
          if (provider.loading) {
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
              padding: const EdgeInsets.all(16),
              children: [
                // ── Financials ─────────────────────────────────────────
                _SectionHeader(
                    label: 'Financials',
                    icon: Icons.account_balance_outlined),
                const SizedBox(height: 12),
                _ConfigField(
                  controller: _txFeeCtrl,
                  label: 'Transaction Fee (%)',
                  hint: 'e.g. 1.5',
                  suffix: '%',
                  isDecimal: true,
                ),
                _ConfigField(
                  controller: _commissionCtrl,
                  label: 'Commission (%)',
                  hint: 'e.g. 5',
                  suffix: '%',
                  isDecimal: true,
                ),
                _ConfigField(
                  controller: _fundingFeesCtrl,
                  label: 'Funding Fees (₦)',
                  hint: 'e.g. 0',
                  prefix: '₦',
                  isDecimal: true,
                ),
                const SizedBox(height: 24),

                // ── Timings ────────────────────────────────────────────
                _SectionHeader(
                    label: 'Timings',
                    icon: Icons.schedule_rounded),
                const SizedBox(height: 12),
                _ConfigField(
                  controller: _autoReleaseCtrl,
                  label: 'Auto Release (hours)',
                  hint: 'e.g. 24',
                  suffix: 'hrs',
                ),
                _ConfigField(
                  controller: _appealWindowCtrl,
                  label: 'Appeal Window (hours)',
                  hint: 'e.g. 48',
                  suffix: 'hrs',
                ),
                _ConfigField(
                  controller: _chatCloseCtrl,
                  label: 'Chat Close (hours)',
                  hint: 'e.g. 72',
                  suffix: 'hrs',
                ),
                const SizedBox(height: 24),

                // ── Utility Bonuses ────────────────────────────────────
                _SectionHeader(
                    label: 'Utility Bonuses (%)',
                    icon: Icons.bolt_rounded),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Cashback % given to users on each utility purchase.',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
                _ConfigField(
                    controller: _bonusAirtimeCtrl,
                    label: 'Airtime',
                    suffix: '%',
                    isDecimal: true),
                _ConfigField(
                    controller: _bonusDataCtrl,
                    label: 'Data',
                    suffix: '%',
                    isDecimal: true),
                _ConfigField(
                    controller: _bonusCableCtrl,
                    label: 'Cable TV',
                    suffix: '%',
                    isDecimal: true),
                _ConfigField(
                    controller: _bonusElectricCtrl,
                    label: 'Electricity',
                    suffix: '%',
                    isDecimal: true),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: Consumer<ConfigProvider>(
                    builder: (_, p, __) => ElevatedButton.icon(
                      onPressed: p.saving ? null : _save,
                      icon: p.saving
                          ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(p.saving ? 'Saving…' : 'Save Changes'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: AppTheme.textSecondary),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    ],
  );
}

class _ConfigField extends StatelessWidget {
  const _ConfigField({
    required this.controller,
    required this.label,
    this.hint,
    this.suffix,
    this.prefix,
    this.isDecimal = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? suffix;
  final String? prefix;
  final bool isDecimal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
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
        if (v == null || v.isEmpty) return 'Required';
        final n = num.tryParse(v);
        if (n == null) return 'Enter a valid number';
        if (n < 0) return 'Cannot be negative';
        return null;
      },
    ),
  );
}