import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../models/vendor_model.dart';

/// Full-detail view of a pending vendor.
/// Read-only — approve/reject actions are done from the list card.
class VendorDetailScreen extends StatelessWidget {
  const VendorDetailScreen({super.key, required this.vendor});

  final VendorModel vendor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ───────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _VendorAvatar(logo: vendor.logo, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.name,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _Badge(
                              label: vendor.vendorType.toUpperCase(),
                              color: AppTheme.accent,
                            ),
                            const SizedBox(width: 6),
                            _Badge(
                              label: vendor.status.toUpperCase(),
                              color: _statusColor(vendor.status),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Business Info ─────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Business Info'),
                  const SizedBox(height: 12),
                  InfoRow(label: 'Email', value: vendor.email.isEmpty ? '—' : vendor.email),
                  InfoRow(label: 'Phone', value: vendor.phone.isEmpty ? '—' : vendor.phone),
                  InfoRow(
                    label: 'CAC Number',
                    value: vendor.cac.isEmpty ? '—' : vendor.cac,
                    copyable: vendor.cac.isNotEmpty,
                  ),
                  InfoRow(
                    label: 'Owner UID',
                    value: vendor.ownerId,
                    copyable: true,
                  ),
                  InfoRow(
                    label: 'Applied',
                    value: AppFormatters.dateTime(vendor.createdAt),
                  ),
                  InfoRow(
                    label: 'Pay on Delivery',
                    value: vendor.allowsPayOnDelivery ? 'Enabled' : 'Disabled',
                    valueColor: vendor.allowsPayOnDelivery
                        ? AppTheme.success
                        : AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Description ───────────────────────────────────────────────
          if (vendor.description.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Description'),
                    const SizedBox(height: 8),
                    Text(
                      vendor.description,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),

          // ── CAC Certificate ───────────────────────────────────────────
          if (vendor.cacCertificateUrl != null &&
              vendor.cacCertificateUrl!.isNotEmpty)
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_outlined,
                      color: AppTheme.accent, size: 20),
                ),
                title: const Text('CAC Certificate',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Tap to copy link',
                    style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.copy,
                    size: 16, color: AppTheme.textSecondary),
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: vendor.cacCertificateUrl!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Certificate URL copied'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),

          // ── Branches ──────────────────────────────────────────────────
          if (vendor.branches.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('Branches (${vendor.branches.length})'),
                    const SizedBox(height: 10),
                    ...vendor.branches.map((b) {
                      final branch = b as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.location_on_outlined,
                                  size: 14, color: AppTheme.success),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                [
                                  branch['street'],
                                  branch['area'],
                                  branch['lga'],
                                  branch['state'],
                                ].where((s) => s != null && (s as String).isNotEmpty).join(', '),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            if (branch['isMainBranch'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('MAIN',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.accent,
                                        letterSpacing: 0.4)),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.danger;
      default:
        return AppTheme.warning;
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _VendorAvatar extends StatelessWidget {
  const _VendorAvatar({required this.logo, required this.size});
  final String logo;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppTheme.accent.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: logo.isNotEmpty
        ? ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(logo,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
              Icons.store, color: AppTheme.accent)),
    )
        : const Icon(Icons.store, color: AppTheme.accent, size: 24),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 12,
      color: AppTheme.textSecondary,
      letterSpacing: 0.3,
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label,
      style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4),
    ),
  );
}