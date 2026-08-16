import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/loading_list.dart';
import 'provider.dart';

class CommissionScreen extends StatefulWidget {
  const CommissionScreen({super.key, required this.partnerId});

  final String partnerId;

  @override
  State<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends State<CommissionScreen> {
  final now = DateTime.now();
  late int _selectedMonth;
  late int _selectedYear;
  final _noteCtrl = TextEditingController();

  static const _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commission Calculator'),
      ),
      body: Consumer<PartnerProvider>(
        builder: (_, p, __) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Period picker ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Period',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Month
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedMonth,
                            dropdownColor: AppTheme.surface,
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontSize: 14),
                            decoration: _dec('Month'),
                            items: List.generate(12, (i) => i + 1)
                                .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(_monthNames[m])))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedMonth = v ?? _selectedMonth),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Year
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedYear,
                            dropdownColor: AppTheme.surface,
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontSize: 14),
                            decoration: _dec('Year'),
                            items: List.generate(5, (i) => now.year - 1 + i)
                                .map((y) => DropdownMenuItem(
                                    value: y, child: Text('$y')))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedYear = v ?? _selectedYear),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: p.calculatingCommission
                            ? null
                            : () => p.calculateCommission(
                                widget.partnerId,
                                _selectedMonth,
                                _selectedYear),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: p.calculatingCommission
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Calculate',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Results ───────────────────────────────────────────────────
              if (p.calculatingCommission) ...[
                const SizedBox(height: 40),
                const LoadingList(),
              ] else if (p.commissionSummary != null) ...[
                Builder(builder: (context) {
                  final s = p.commissionSummary!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_monthNames[s.month]} ${s.year} — ${s.partnerName}',
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                            const Divider(height: 20, color: AppTheme.divider),
                            _Row('Total vendors', '${s.vendorCount}'),
                            _Row('Active vendors', '${s.activeVendorCount}'),
                            _Row('Eligible vendors', '${s.eligibleVendorCount}',
                                color: AppTheme.primary),
                            _Row('Transaction count', '${s.transactionCount}'),
                            _Row('Eligible volume',
                                AppFormatters.naira(s.eligibleVolume),
                                color: AppTheme.success),
                            _Row('Excluded/refunded',
                                AppFormatters.naira(s.excludedAmount),
                                color: AppTheme.danger),
                            const Divider(height: 16, color: AppTheme.divider),
                            _Row('Commission rate', '${s.commissionRate}%'),
                            _Row(
                                'Commission amount',
                                AppFormatters.naira(s.calculatedCommission),
                                color: AppTheme.success,
                                bold: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Existing payout warning OR create payout section
                      if (s.existingPayout != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.warning.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: AppTheme.warning, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'A payout already exists for this period '
                                  '(${s.existingPayout!.status}). '
                                  'Cancel it first to create a new one.',
                                  style: const TextStyle(
                                      color: AppTheme.warning, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        // Create payout section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Create Payout',
                                  style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                'This will finalize ${AppFormatters.naira(s.calculatedCommission)} '
                                'for ${_monthNames[s.month]} ${s.year}. '
                                'The values are snapshotted and immutable once paid.',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _noteCtrl,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary, fontSize: 14),
                                decoration: _dec('Payment reference / note (optional)'),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: p.savingPayout
                                      ? null
                                      : () => _createPayout(context, p, s),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.success,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  child: p.savingPayout
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : Text(
                                          'Finalize ${AppFormatters.naira(s.calculatedCommission)}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Per-vendor breakdown
                      if (s.vendorBreakdown.isNotEmpty) ...[
                        const Text('Vendor Breakdown',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        ...s.vendorBreakdown.map((v) => _VendorBreakdownTile(v: v)),
                      ],
                    ],
                  );
                }),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  void _createPayout(BuildContext context, PartnerProvider p,
      dynamic s) async {
    final ok = await p.createPayout(
      partnerId: widget.partnerId,
      month: s.month,
      year: s.year,
      transactionAmount: s.eligibleVolume,
      commissionRate: s.commissionRate,
      commissionAmount: s.calculatedCommission,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(
        content: Text('Payout created — go to partner detail to mark it paid'),
        backgroundColor: AppTheme.success,
      ));
      Navigator.pop(this.context);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.color, this.bold = false});

  final String label;
  final String value;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: color ?? AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _VendorBreakdownTile extends StatelessWidget {
  const _VendorBreakdownTile({required this.v});

  final Map<String, dynamic> v;

  @override
  Widget build(BuildContext context) {
    final isActive = v['isActive'] as bool? ?? false;
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v['vendorName']?.toString() ?? '',
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                  Text(
                    '${v['transactionCount']} orders · '
                    '${AppFormatters.naira((v['eligibleVolume'] as num?)?.toDouble() ?? 0)}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.success.withValues(alpha: 0.15)
                    : AppTheme.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isActive ? 'Active' : 'Expired',
                style: TextStyle(
                    color: isActive ? AppTheme.success : AppTheme.danger,
                    fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
