import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/error_view.dart';
import '../models/vendor_model.dart';
import '../providers/vendor_provider.dart';

/// Full-detail view of a vendor (§4.3). Takes a [vendorId] and fetches the full
/// record from GET /admin/vendor/:vendorId; [lite] (the tapped list card) backs
/// a header while loading. Actions are contextual to status:
///   pending → Approve / Reject, approved → Suspend,
///   suspended → Reinstate, rejected → Approve (second chance).
class VendorDetailScreen extends StatefulWidget {
  const VendorDetailScreen({super.key, required this.vendorId, this.lite});

  final String vendorId;
  final VendorLite? lite;

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  VendorModel? _vendor;
  bool _loading = true;
  String? _error;
  bool _acting = false;
  bool _changed = false; // pop result → list refresh hint

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final v = await context.read<VendorProvider>().getDetail(widget.vendorId);
      if (!mounted) return;
      setState(() {
        _vendor = v;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _approve() async {
    final v = _vendor!;
    final ok = await _confirm('Approve ${v.name}?',
        'The vendor will be notified and their store will become visible.',
        confirmLabel: 'Approve');
    if (!ok || !mounted) return;
    await _runAction(() => context.read<VendorProvider>().approve(v.id),
        successMsg: '${v.name} approved ✓');
  }

  Future<void> _reject() async {
    final v = _vendor!;
    final reason = await _askReason('Reject ${v.name}',
        hint: 'e.g. Incomplete documents',
        fallback: 'Application did not meet our requirements');
    if (reason == null || !mounted) return;
    await _runAction(
        () => context.read<VendorProvider>().reject(v.id, reason: reason),
        successMsg: '${v.name} rejected');
  }

  Future<void> _suspend() async {
    final v = _vendor!;
    final reason = await _askReason('Suspend ${v.name}',
        hint: 'e.g. Repeated order disputes',
        fallback: 'Suspended by admin');
    if (reason == null || !mounted) return;
    await _runAction(
        () => context.read<VendorProvider>().suspend(v.id, reason: reason),
        successMsg: '${v.name} suspended');
  }

  Future<void> _reinstate() async {
    final v = _vendor!;
    final ok = await _confirm('Reinstate ${v.name}?',
        'The store becomes visible again and can receive new orders.',
        confirmLabel: 'Reinstate');
    if (!ok || !mounted) return;
    await _runAction(() => context.read<VendorProvider>().reinstate(v.id),
        successMsg: '${v.name} reinstated ✓');
  }

  Future<void> _runAction(Future<String?> Function() op,
      {required String successMsg}) async {
    setState(() => _acting = true);
    final err = await op();
    if (!mounted) return;
    setState(() => _acting = false);
    _showSnack(err ?? successMsg, isError: err != null);
    if (err == null) {
      _changed = true;
      await _fetch(); // re-pull so the badge/banner reflect the new status
    }
  }

  Future<bool> _confirm(String title, String body,
      {required String confirmLabel}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content:
            Text(body, style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _askReason(String title,
      {required String hint, required String fallback}) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: 'Reason', hintText: hint),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context,
                ctrl.text.trim().isEmpty ? fallback : ctrl.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Vendor Detail')),
        body: _body(),
        bottomNavigationBar: _vendor != null ? _actionsBar(_vendor!) : null,
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _fetch);
    }
    if (_loading && _vendor == null) {
      // Lite header from the tapped card while the full record loads.
      return Column(
        children: [
          if (widget.lite != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _headerCard(
                name: widget.lite!.name,
                logo: widget.lite!.logo,
                vendorType: widget.lite!.vendorType,
                status: widget.lite!.status,
              ),
            ),
          const Expanded(
            child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary)),
          ),
        ],
      );
    }
    final vendor = _vendor!;
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(
            name: vendor.name,
            logo: vendor.logo,
            vendorType: vendor.vendorType,
            status: vendor.status,
          ),
          const SizedBox(height: 12),

          // ── Status banners ─────────────────────────────────────────────
          if (vendor.isSuspended)
            _reasonBanner(
              icon: Icons.block_rounded,
              color: AppTheme.danger,
              title: 'Suspended',
              reason: vendor.suspensionReason ?? 'Suspended by admin',
            ),
          if (vendor.status == 'rejected')
            _reasonBanner(
              icon: Icons.cancel_outlined,
              color: AppTheme.warning,
              title: 'Rejected',
              reason: vendor.rejectionMessage ??
                  'Application did not meet our requirements',
            ),

          // ── Business Info ──────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Business Info'),
                  const SizedBox(height: 12),
                  InfoRow(
                      label: 'Email',
                      value: vendor.email.isEmpty ? '—' : vendor.email),
                  InfoRow(
                      label: 'Phone',
                      value: vendor.phone.isEmpty ? '—' : vendor.phone),
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
                  InfoRow(
                    label: 'Visible',
                    value: vendor.isVisible ? 'Yes' : 'No',
                    valueColor: vendor.isVisible
                        ? AppTheme.success
                        : AppTheme.textSecondary,
                  ),
                  InfoRow(
                      label: 'Orders', value: vendor.orderCount.toString()),
                  InfoRow(
                      label: 'Hardware',
                      value: '${vendor.hardwareOrderCount} orders'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Description ────────────────────────────────────────────────
          if (vendor.description.isNotEmpty) ...[
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
          ],

          // ── CAC Certificate ────────────────────────────────────────────
          if (vendor.cacCertificateUrl != null &&
              vendor.cacCertificateUrl!.isNotEmpty) ...[
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.08),
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
          ],

          // ── Branches ───────────────────────────────────────────────────
          if (vendor.branches.isNotEmpty)
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
                      // Per-km delivery (roadmap Phase 9): show the branch
                      // pin when set — tap copies an OSM link for review
                      // (vendors may register from home; admins can sanity-
                      // check the pin actually sits on a shop).
                      final dLat = branch['deliveryLat'];
                      final dLng = branch['deliveryLng'];
                      final hasPin = dLat is num && dLng is num;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.success.withValues(alpha: 0.08),
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
                                ]
                                    .where((s) =>
                                        s != null && (s as String).isNotEmpty)
                                    .join(', '),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            if (branch['isMainBranch'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.accent.withValues(alpha: 0.08),
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
                            if (hasPin)
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 36, top: 3),
                                child: GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text:
                                            'https://www.openstreetmap.org/?mlat=$dLat&mlon=$dLng#map=18/$dLat/$dLng'));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text('Map link copied'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 1),
                                    ));
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.push_pin_outlined,
                                          size: 11, color: AppTheme.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Delivery pin ${(dLat).toStringAsFixed(5)}, ${(dLng).toStringAsFixed(5)}'
                                        '${branch['deliveryEnabled'] == true ? ' · ${branch['deliveryRadiusKm'] ?? 10} km' : ' · OFF'}'
                                        ' · tap to copy map link',
                                        style: const TextStyle(
                                            fontSize: 10.5,
                                            color: AppTheme.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _headerCard({
    required String name,
    required String logo,
    required String vendorType,
    required String status,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _VendorAvatar(logo: logo, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Badge(
                        label: vendorType.toUpperCase(),
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 6),
                      _Badge(
                        label: status.toUpperCase(),
                        color: vendorStatusColor(status),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reasonBanner({
    required IconData icon,
    required Color color,
    required String title,
    required String reason,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 3),
                Text(reason,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Contextual actions bar (§4.3).
  Widget? _actionsBar(VendorModel vendor) {
    final List<Widget> buttons;
    switch (vendor.status) {
      case 'pending':
        buttons = [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _acting ? null : _reject,
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _acting ? null : _approve,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Approve'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            ),
          ),
        ];
        break;
      case 'approved':
        buttons = [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _acting ? null : _suspend,
              icon: const Icon(Icons.block_rounded, size: 16),
              label: const Text('Suspend store'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
              ),
            ),
          ),
        ];
        break;
      case 'suspended':
        buttons = [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _acting ? null : _reinstate,
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: const Text('Reinstate store'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            ),
          ),
        ];
        break;
      case 'rejected':
        buttons = [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _acting ? null : _approve,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Approve (second chance)'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            ),
          ),
        ];
        break;
      default:
        return null;
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 48,
          child: _acting
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primary),
                  ),
                )
              : Row(children: buttons),
        ),
      ),
    );
  }
}

/// Status → color, shared with list chips (suspended included, §4.3).
Color vendorStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return AppTheme.success;
    case 'rejected':
      return AppTheme.danger;
    case 'suspended':
      return AppTheme.danger;
    default:
      return AppTheme.warning;
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
      color: AppTheme.accent.withValues(alpha: 0.08),
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
      color: color.withValues(alpha: 0.1),
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
