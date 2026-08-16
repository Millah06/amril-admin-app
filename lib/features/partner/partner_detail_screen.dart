import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_list.dart';
import 'commission_screen.dart';
import 'model.dart';
import 'provider.dart';

class PartnerDetailScreen extends StatefulWidget {
  const PartnerDetailScreen({super.key, required this.partnerId});

  final String partnerId;

  @override
  State<PartnerDetailScreen> createState() => _PartnerDetailScreenState();
}

class _PartnerDetailScreenState extends State<PartnerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PartnerProvider>().loadDetail(widget.partnerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<PartnerProvider>().loadDetail(widget.partnerId),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit partner',
            onPressed: () => _showEditSheet(context),
          ),
        ],
      ),
      body: Consumer<PartnerProvider>(
        builder: (_, p, __) {
          if (p.loadingDetail) return const LoadingList();
          if (p.error != null && p.detail == null) {
            return ErrorView(
                message: p.error!,
                onRetry: () => p.loadDetail(widget.partnerId));
          }
          final d = p.detail;
          if (d == null) return const SizedBox.shrink();

          final now = DateTime.now();
          final activeLinks =
              d.vendorLinks.where((l) => l.expiresAt.isAfter(now)).toList();
          final expiredLinks =
              d.vendorLinks.where((l) => !l.expiresAt.isAfter(now)).toList();

          return RefreshIndicator(
            onRefresh: () => p.loadDetail(widget.partnerId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Profile card ─────────────────────────────────────────
                _InfoCard(
                  children: [
                    _InfoRow(
                        label: 'Name',
                        value: d.name,
                        valueStyle: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    _InfoRow(
                        label: 'Code',
                        value: d.partnerCode,
                        valueStyle: const TextStyle(
                            color: AppTheme.primary,
                            fontFamily: 'monospace',
                            fontSize: 14)),
                    _InfoRow(
                        label: 'Certificate',
                        value: d.certificateNumber,
                        valueStyle: const TextStyle(
                            color: AppTheme.accent,
                            fontFamily: 'monospace',
                            fontSize: 13)),
                    _InfoRow(label: 'Tier', value: _tierLabel(d.tier)),
                    _InfoRow(label: 'Phone', value: d.phone.isEmpty ? '—' : d.phone),
                    _InfoRow(label: 'Email', value: d.email.isEmpty ? '—' : d.email),
                    _InfoRow(
                        label: 'Commission',
                        value: '${d.commissionRate}%',
                        valueStyle: const TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600)),
                    _InfoRow(
                        label: 'Status',
                        value: d.isActive ? 'Active' : 'Inactive',
                        valueStyle: TextStyle(
                            color: d.isActive
                                ? AppTheme.success
                                : AppTheme.danger,
                            fontWeight: FontWeight.w600)),
                    if (d.userId != null)
                      _InfoRow(
                          label: 'User Account',
                          value: d.userId!,
                          valueStyle: const TextStyle(
                              color: AppTheme.success,
                              fontFamily: 'monospace',
                              fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Link User Account (if not yet linked) ────────────────
                if (!d.hasUserAccount)
                  Card(
                    color: AppTheme.surface,
                    child: ListTile(
                      leading: const Icon(Icons.link_rounded,
                          color: AppTheme.warning),
                      title: const Text('Link User Account',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      subtitle: const Text(
                          'Connect a User ID to enable partner portal access',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 14, color: AppTheme.textSecondary),
                      onTap: () => _showLinkUserSheet(context),
                    ),
                  ),
                if (!d.hasUserAccount) const SizedBox(height: 16),

                // ── Stats row ─────────────────────────────────────────────
                Row(children: [
                  _StatChip(
                      label: 'Total',
                      value: d.vendorLinks.length.toString(),
                      color: AppTheme.primary),
                  const SizedBox(width: 8),
                  _StatChip(
                      label: 'Active',
                      value: activeLinks.length.toString(),
                      color: AppTheme.success),
                  const SizedBox(width: 8),
                  _StatChip(
                      label: 'Expired',
                      value: expiredLinks.length.toString(),
                      color: AppTheme.danger),
                ]),
                const SizedBox(height: 16),

                // ── Commission calculator entry ────────────────────────────
                Card(
                  color: AppTheme.surface,
                  child: ListTile(
                    leading: const Icon(Icons.calculate_rounded,
                        color: AppTheme.primary),
                    title: const Text('Calculate Commission',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    subtitle: const Text(
                        'Monthly eligible volume + payout creation',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppTheme.textSecondary),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            CommissionScreen(partnerId: widget.partnerId))),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Vendor list ───────────────────────────────────────────
                _SectionHeader(
                  title: 'Vendors (${d.vendorLinks.length})',
                  trailing: TextButton.icon(
                    onPressed: () => _showAssignVendorSheet(context),
                    icon: const Icon(Icons.add_rounded,
                        size: 16, color: AppTheme.primary),
                    label: const Text('Assign',
                        style: TextStyle(
                            color: AppTheme.primary, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),
                if (d.vendorLinks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('No vendors assigned yet',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ),
                  )
                else
                  ...d.vendorLinks
                      .map((l) => _VendorLinkTile(
                          link: l, partnerId: widget.partnerId)),
                const SizedBox(height: 16),

                // ── Payout history ────────────────────────────────────────
                _SectionHeader(title: 'Payout History'),
                const SizedBox(height: 8),
                if (d.payouts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('No payouts yet',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ),
                  )
                else
                  ...d.payouts
                      .map((pay) =>
                          _PayoutTile(payout: pay, partnerId: widget.partnerId)),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    final d = context.read<PartnerProvider>().detail;
    if (d == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditPartnerSheet(partner: d),
    );
  }

  void _showAssignVendorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AssignVendorSheet(partnerId: widget.partnerId),
    );
  }

  void _showLinkUserSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LinkUserSheet(partnerId: widget.partnerId),
    );
  }

  String _tierLabel(String tier) {
    switch (tier) {
      case 'STATE_PARTNER':
        return 'State Partner';
      case 'REGIONAL_PARTNER':
        return 'Regional Partner';
      case 'NATIONAL_PARTNER':
        return 'National Partner';
      default:
        return 'Partner';
    }
  }
}

// ── Vendor link tile ──────────────────────────────────────────────────────────

class _VendorLinkTile extends StatelessWidget {
  const _VendorLinkTile(
      {required this.link, required this.partnerId});

  final PartnerVendorLink link;
  final String partnerId;

  @override
  Widget build(BuildContext context) {
    final isActive = link.isActive;
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: Text(
                link.vendorName.isNotEmpty
                    ? link.vendorName[0].toUpperCase()
                    : 'V',
                style: const TextStyle(color: AppTheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(link.vendorName,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(
                    '${link.branchCount} branch${link.branchCount == 1 ? '' : 'es'} · ${link.vendorType}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  Text(
                    'Assigned ${AppFormatters.date(link.assignedAt)} · '
                    'Expires ${AppFormatters.date(link.expiresAt)}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isActive)
                  TextButton(
                    onPressed: () => _expire(context),
                    child: const Text('Expire',
                        style: TextStyle(
                            color: AppTheme.danger, fontSize: 11)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _expire(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Expire assignment?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'This will expire ${link.vendorName}\'s active assignment. '
          'Historical commission records are preserved.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Expire',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await context.read<PartnerProvider>().removeVendorAssignment(
        partnerId, link.id);
  }
}

// ── Payout tile ───────────────────────────────────────────────────────────────

class _PayoutTile extends StatelessWidget {
  const _PayoutTile({required this.payout, required this.partnerId});

  final PartnerPayout payout;
  final String partnerId;

  @override
  Widget build(BuildContext context) {
    final statusColor = payout.status == 'PAID'
        ? AppTheme.success
        : payout.status == 'CANCELLED'
            ? AppTheme.danger
            : AppTheme.warning;

    final monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${monthNames[payout.month]} ${payout.year}',
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Volume: ${AppFormatters.naira(payout.transactionAmount)}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  Text(
                    'Rate: ${payout.commissionRate}% → ${AppFormatters.naira(payout.commissionAmount)}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  if (payout.note != null && payout.note!.isNotEmpty)
                    Text('Note: ${payout.note}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(payout.status,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                if (payout.status == 'PENDING') ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => _markPaid(context),
                    child: const Text('Mark Paid',
                        style: TextStyle(
                            color: AppTheme.success, fontSize: 11)),
                  ),
                  TextButton(
                    onPressed: () => _cancel(context),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: AppTheme.danger, fontSize: 11)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _markPaid(BuildContext context) async {
    final noteCtrl = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Mark as Paid',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: noteCtrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Payment reference / note (optional)',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, noteCtrl.text.trim()),
              child: const Text('Confirm',
                  style: TextStyle(color: AppTheme.success))),
        ],
      ),
    );
    if (note == null || !context.mounted) return;
    await context.read<PartnerProvider>().markPayoutPaid(
        partnerId, payout.id,
        note: note.isEmpty ? null : note);
  }

  void _cancel(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Cancel payout?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This marks the payout as CANCELLED.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, cancel',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await context.read<PartnerProvider>().cancelPayout(partnerId, payout.id);
  }
}

// ── Small shared widgets ──────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.label, required this.value, this.valueStyle});

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: valueStyle ??
                    const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Edit partner sheet ────────────────────────────────────────────────────────

class _EditPartnerSheet extends StatefulWidget {
  const _EditPartnerSheet({required this.partner});
  final PartnerDetail partner;

  @override
  State<_EditPartnerSheet> createState() => _EditPartnerSheetState();
}

class _EditPartnerSheetState extends State<_EditPartnerSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _rate;
  late String _tier;
  late String _status;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.partner.name);
    _phone = TextEditingController(text: widget.partner.phone);
    _email = TextEditingController(text: widget.partner.email);
    _rate = TextEditingController(
        text: widget.partner.commissionRate.toString());
    _tier = widget.partner.tier;
    _status = widget.partner.status;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _rate]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Edit Partner',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(_name, 'Name'),
            const SizedBox(height: 10),
            _buildField(_phone, 'Phone', type: TextInputType.phone),
            const SizedBox(height: 10),
            _buildField(_email, 'Email', type: TextInputType.emailAddress),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _tier,
              dropdownColor: AppTheme.surface,
              style:
                  const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: _dec('Tier'),
              items: const [
                DropdownMenuItem(value: 'PARTNER', child: Text('Partner')),
                DropdownMenuItem(
                    value: 'STATE_PARTNER', child: Text('State Partner')),
                DropdownMenuItem(
                    value: 'REGIONAL_PARTNER',
                    child: Text('Regional Partner')),
                DropdownMenuItem(
                    value: 'NATIONAL_PARTNER',
                    child: Text('National Partner')),
              ],
              onChanged: (v) => setState(() => _tier = v ?? _tier),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _status,
              dropdownColor: AppTheme.surface,
              style:
                  const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: _dec('Status'),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 10),
            _buildField(_rate, 'Commission Rate %',
                type: TextInputType.number),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Consumer<PartnerProvider>(
                builder: (_, p, __) => ElevatedButton(
                  onPressed: p.loading ? null : () => _save(context, p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: p.loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: _dec(label),
    );
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

  void _save(BuildContext context, PartnerProvider p) async {
    final rate = double.tryParse(_rate.text.trim());
    final ok = await p.updatePartner(
      widget.partner.id,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      tier: _tier,
      status: _status,
      commissionRate: rate,
    );
    if (ok && context.mounted) Navigator.pop(context);
  }
}

// ── Assign vendor sheet ───────────────────────────────────────────────────────

class _AssignVendorSheet extends StatefulWidget {
  const _AssignVendorSheet({required this.partnerId});
  final String partnerId;

  @override
  State<_AssignVendorSheet> createState() => _AssignVendorSheetState();
}

class _AssignVendorSheetState extends State<_AssignVendorSheet> {
  final _vendorId = TextEditingController();

  @override
  void dispose() {
    _vendorId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Assign Vendor',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the Vendor ID to assign. The vendor will be linked for '
            '6 months from today.',
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _vendorId,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Vendor ID',
              labelStyle: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Consumer<PartnerProvider>(
            builder: (_, p, __) {
              if (p.error != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(p.error!,
                      style: const TextStyle(
                          color: AppTheme.danger, fontSize: 13)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          SizedBox(
            width: double.infinity,
            child: Consumer<PartnerProvider>(
              builder: (_, p, __) => ElevatedButton(
                onPressed: p.loading ? null : () => _assign(context, p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: p.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Assign',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _assign(BuildContext context, PartnerProvider p) async {
    final vid = _vendorId.text.trim();
    if (vid.isEmpty) return;
    final ok = await p.assignVendor(widget.partnerId, vid);
    if (ok && context.mounted) Navigator.pop(context);
  }
}

// ── Link user sheet ───────────────────────────────────────────────────────────

class _LinkUserSheet extends StatefulWidget {
  const _LinkUserSheet({required this.partnerId});

  final String partnerId;

  @override
  State<_LinkUserSheet> createState() => _LinkUserSheetState();
}

class _LinkUserSheetState extends State<_LinkUserSheet> {
  final _userId = TextEditingController();

  @override
  void dispose() {
    _userId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Link User Account',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the User ID to link. This will grant the user access to '
            'the partner portal.',
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _userId,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'User ID',
              labelStyle: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Consumer<PartnerProvider>(
            builder: (_, p, __) {
              if (p.error != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(p.error!,
                      style: const TextStyle(
                          color: AppTheme.danger, fontSize: 13)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          SizedBox(
            width: double.infinity,
            child: Consumer<PartnerProvider>(
              builder: (_, p, __) => ElevatedButton(
                onPressed: p.loading ? null : () => _link(context, p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: p.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Link Account',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _link(BuildContext context, PartnerProvider p) async {
    final uid = _userId.text.trim();
    if (uid.isEmpty) return;
    final ok = await p.linkUser(widget.partnerId, uid);
    if (ok && context.mounted) Navigator.pop(context);
  }
}
