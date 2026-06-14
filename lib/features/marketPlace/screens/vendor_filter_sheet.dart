import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/vendor_provider.dart';

class VendorFilterSheet extends StatefulWidget {
  const VendorFilterSheet({super.key});

  @override
  State<VendorFilterSheet> createState() => _VendorFilterSheetState();
}

class _VendorFilterSheetState extends State<VendorFilterSheet> {

  String? verificationStatus;
  String? status;
  String? vendorType;


  void _apply() {
    final v = context.read<VendorProvider>();
    v.applyFilter(verificationStatus, status, vendorType);
    Navigator.pop(context);
  }

  void _reset() {
    final v = context.read<VendorProvider>();
    v.getVendors(
        null,
        null,
        null,
      null,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Filter Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 20),
          const _FilterLabel('Vendor Status'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['pending' , 'approved', 'rejected'].map((t) {
              final sel = status == t;
              return ChoiceChip(
                label: Text(t),
                selected: sel,
                onSelected: (_) => setState(() => status = sel ? null : t),
                selectedColor: AppTheme.accent.withOpacity(0.12),
                labelStyle: TextStyle(
                  color: sel ? AppTheme.accent : AppTheme.textPrimary,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const _FilterLabel('Verification Status'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['unverified', 'pending', 'verified', 'rejected'].map((t) {
              final sel = verificationStatus == t;
              return ChoiceChip(
                label: Text(t),
                selected: sel,
                onSelected: (_) => setState(() => verificationStatus = sel ? null : t),
                selectedColor: AppTheme.accent.withOpacity(0.12),
                labelStyle: TextStyle(
                  color: sel ? AppTheme.accent : AppTheme.textPrimary,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const _FilterLabel('Vendor Type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['restaurant', ' grocery', 'drinks', 'retail'].map((t) {
              final sel = vendorType == t;
              return ChoiceChip(
                label: Text(t),
                selected: sel,
                onSelected: (_) => setState(() => vendorType = sel ? null : t),
                selectedColor: AppTheme.accent.withOpacity(0.12),
                labelStyle: TextStyle(
                  color: sel ? AppTheme.accent : AppTheme.textPrimary,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(onPressed: _apply, child: const Text('Apply')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppTheme.textSecondary,
      letterSpacing: 0.5,
    ),
  );
}