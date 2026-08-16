import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/empty_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_list.dart';
import 'model.dart';
import 'partner_detail_screen.dart';
import 'provider.dart';

class PartnerListScreen extends StatefulWidget {
  const PartnerListScreen({super.key});

  @override
  State<PartnerListScreen> createState() => _PartnerListScreenState();
}

class _PartnerListScreenState extends State<PartnerListScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PartnerProvider>().loadPartners();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partners'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<PartnerProvider>().loadPartners(silent: true),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create partner',
            onPressed: () => _showCreateSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by name or partner code…',
                hintStyle:
                    const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.textSecondary),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppTheme.textSecondary),
                        onPressed: () {
                          _search.clear();
                          context
                              .read<PartnerProvider>()
                              .loadPartners(silent: true);
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => context
                  .read<PartnerProvider>()
                  .loadPartners(silent: true, search: v.trim().isEmpty ? null : v.trim()),
            ),
          ),
          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: Consumer<PartnerProvider>(
              builder: (_, p, __) {
                if (p.loading) return const LoadingList();
                if (p.error != null) {
                  return ErrorView(
                    message: p.error!,
                    onRetry: () => p.loadPartners(),
                  );
                }
                if (p.partners.isEmpty) {
                  return EmptyView(
                    icon: Icons.handshake_outlined,
                    message: 'No partners yet',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => p.loadPartners(silent: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: p.partners.length,
                    itemBuilder: (_, i) =>
                        _PartnerTile(partner: p.partners[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CreatePartnerSheet(),
    );
  }
}

// ── Partner tile ──────────────────────────────────────────────────────────────

class _PartnerTile extends StatelessWidget {
  const _PartnerTile({required this.partner});

  final PartnerLite partner;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      child: ListTile(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PartnerDetailScreen(partnerId: partner.id))),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
          child: Text(
            partner.name.isNotEmpty ? partner.name[0].toUpperCase() : 'P',
            style: const TextStyle(
                color: AppTheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(partner.name,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(partner.partnerCode,
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontFamily: 'monospace')),
            Text(
              '${_tierLabel(partner.tier)} · ${partner.vendorLinkCount} vendors',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: partner.isActive
                ? AppTheme.success.withValues(alpha: 0.15)
                : AppTheme.danger.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            partner.isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: partner.isActive ? AppTheme.success : AppTheme.danger,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  String _tierLabel(String tier) {
    switch (tier) {
      case 'STATE_PARTNER':
        return 'State';
      case 'REGIONAL_PARTNER':
        return 'Regional';
      case 'NATIONAL_PARTNER':
        return 'National';
      default:
        return 'Partner';
    }
  }
}

// ── Create partner bottom sheet ───────────────────────────────────────────────

class _CreatePartnerSheet extends StatefulWidget {
  const _CreatePartnerSheet();

  @override
  State<_CreatePartnerSheet> createState() => _CreatePartnerSheetState();
}

class _CreatePartnerSheetState extends State<_CreatePartnerSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _rate = TextEditingController(text: '1');
  String _tier = 'PARTNER';

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Create Partner',
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
          _Field(controller: _name, label: 'Full Name *'),
          const SizedBox(height: 10),
          _Field(
              controller: _phone,
              label: 'Phone',
              type: TextInputType.phone),
          const SizedBox(height: 10),
          _Field(
              controller: _email,
              label: 'Email',
              type: TextInputType.emailAddress),
          const SizedBox(height: 10),
          // Tier dropdown
          DropdownButtonFormField<String>(
            initialValue: _tier,
            dropdownColor: AppTheme.surface,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: _inputDec('Tier'),
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
          _Field(
              controller: _rate,
              label: 'Commission Rate % (default 1)',
              type: TextInputType.number),
          const SizedBox(height: 20),
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
                onPressed: p.loading ? null : () => _submit(context, p),
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
                    : const Text('Create',
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

  void _submit(BuildContext context, PartnerProvider p) async {
    if (_name.text.trim().isEmpty) return;
    final rate = double.tryParse(_rate.text.trim()) ?? 1;
    final ok = await p.createPartner(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      tier: _tier,
      commissionRate: rate,
    );
    if (ok && context.mounted) Navigator.pop(context);
  }

  InputDecoration _inputDec(String label) => InputDecoration(
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

// ── Shared text field widget ───────────────────────────────────────────────────
class _Field extends StatelessWidget {
  const _Field(
      {required this.controller,
      required this.label,
      this.type = TextInputType.text});

  final TextEditingController controller;
  final String label;
  final TextInputType type;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );
  }
}
