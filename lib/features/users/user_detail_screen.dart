import 'package:admin_panel/features/users/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

import '../../../shared/widgets/confirm_dialog.dart';
import '../../core/erorrs/app_exception.dart';


class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await DioClient.get(ApiConstants.adminUserDetail(widget.userId));
      setState(() => _data = data as Map<String, dynamic>);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _toggleBlock() async {
    final isActive = _data!['active'] as bool;
    final action = isActive ? 'block' : 'unblock';

    String? reason;
    if (isActive) {
      reason = await _showReasonDialog('Block User', 'Provide a reason (optional)');
    }

    final confirmed = await showConfirmDialog(
      context,
      title: '${action == 'block' ? 'Block' : 'Unblock'} User',
      message: 'Are you sure you want to $action ${_data!['name']}?',
      confirmLabel: action == 'block' ? 'Block' : 'Unblock',
      isDestructive: action == 'block',
    );
    if (!confirmed) return;

    final err = await context.read<UsersProvider>().setUserActiveStatus(
      userId: widget.userId,
      active: !isActive,
      reason: reason,
    );

    if (!mounted) return;
    if (err != null) {
      _showError(err);
    } else {
      setState(() => _data!['active'] = !isActive);
      _showSuccess('User ${action}ed successfully');
    }
  }

  Future<void> _changeRole() async {
    final currentRole = _data!['role'] as String;
    final roles = ['user', 'vendor', 'admin'];

    final selected = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Change Role'),
        children: roles
            .map((r) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, r),
          child: Row(
            children: [
              Radio<String>(
                value: r,
                groupValue: currentRole,
                onChanged: (_) => Navigator.pop(context, r),
                activeColor: AppTheme.accent,
              ),
              Text(r, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ))
            .toList(),
      ),
    );

    if (selected == null || selected == currentRole) return;

    final err = await context.read<UsersProvider>().updateRole(
      userId: widget.userId,
      role: selected,
    );
    if (!mounted) return;
    if (err != null) {
      _showError(err);
    } else {
      setState(() => _data!['role'] = selected);
      _showSuccess('Role updated to $selected');
    }
  }

  Future<void> _reviewKyc() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (_) => const _KycReviewDialog(),
    );
    if (result == null) return;

    final err = await context.read<UsersProvider>().updateKyc(
      userId: widget.userId,
      status: result['status']!,
      reason: result['reason'],
    );
    if (!mounted) return;
    if (err != null) {
      _showError(err);
    } else {
      _showSuccess('KYC ${result['status']} successfully');
      _load(); // reload to show updated badge
    }
  }

  Future<void> _manualCredit() async {
    final result = await _showAmountDialog('Manual Credit', isCredit: true);
    if (result == null) return;

    try {
      await DioClient.post(ApiConstants.adminManualCredit, data: {
        'userId': widget.userId,
        'amount': result['amount'],
        'reason': result['reason'],
        'operationBalance': result['operationBalance']
      });
      if (!mounted) return;
      _showSuccess('₦${result['amount']} credited successfully');
      _load();
    } on AppException catch (e) {
      if (mounted) _showError(e.message);
    }
  }

  Future<void> _manualDebit() async {
    final result = await _showAmountDialog('Manual Debit', isCredit: false);
    if (result == null) return;

    final confirmed = await showConfirmDialog(
     context,
      title: 'Confirm Debit',
      message: 'Debit ₦${result['amount']} from ${_data!['name']}?',
      confirmLabel: 'Debit',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      await DioClient.post(ApiConstants.adminManualDebit, data: {
        'userId': widget.userId,
        'amount': result['amount'],
        'reason': result['reason'],
        'operationBalance': result['operationBalance']
      });
      if (!mounted) return;
      _showSuccess('₦${result['amount']} debited successfully');
      _load();
    } on AppException catch (e) {
      if (mounted) _showError(e.message);
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<String?> _showReasonDialog(String title, String hint) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: hint),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showAmountDialog(String title, {required bool isCredit}) async {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String ? operationBalance;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (₦)',
                  prefixText: '₦ ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount required';
                  if (double.tryParse(v) == null) return 'Invalid amount';
                  if (double.parse(v) <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason'),
                validator: (v) => v == null || v.isEmpty ? 'Reason required' : null,
              ),
              DropdownButton<String>(items: List.generate(3, (index) {
                Map items = {'Available Balance':
                'availableBalance',
                  'Reward Balance':'rewardBalance', 'Locked Balance' : 'lockedBalance'};

                return DropdownMenuItem(value:
                items.values.elementAtOrNull(index), child: Text(items.keys.toList()[index], style: TextStyle(color: Colors.white),));

              }),
                  onChanged: (value) {

                setState(() {
                  operationBalance = value;
                });


                  }
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: isCredit
                ? null
                : ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, {
                  'amount': double.parse(amountCtrl.text),
                  'reason': reasonCtrl.text.trim(),
                  'operationBalance' : operationBalance,
                });
              }
            },
            child: Text(isCredit ? 'Credit' : 'Debit'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating),
  );

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
  );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Detail'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppTheme.danger)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _data!;
    final profile = d['userProfile'] as Map<String, dynamic>?;
    final fiat = (d['wallet'] as Map<String, dynamic>?)?['fiat'] as Map<String, dynamic>?;
    final kyc = d['kyc'] as Map<String, dynamic>?;
    final accounts = d['virtualAccount'] as List?;
    final recentTx = d['transactions'] as List? ?? [];
    final isActive = d['active'] as bool;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header card ──────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.accent.withOpacity(0.12),
                  backgroundImage: (profile?['avatarUrl'] as String?)?.isNotEmpty == true
                      ? CachedNetworkImageProvider(profile!['avatarUrl'] as String)
                      : null,
                  child: (profile?['avatarUrl'] as String?)?.isEmpty != false
                      ? Text(
                    (d['name'] as String)[0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 22),
                  )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              d['name'] as String,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (profile?['isVerified'] == true)
                            const Icon(Icons.verified_rounded, color: AppTheme.accent, size: 16),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(d['email'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Badge(label: d['role'] as String, color: AppTheme.accent),
                          const SizedBox(width: 6),
                          _Badge(
                            label: isActive ? 'Active' : 'Blocked',
                            color: isActive ? AppTheme.success : AppTheme.danger,
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

        // ── Wallet balances ──────────────────────────────────────────────
        if (fiat != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('Wallet'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _BalanceTile(
                          label: 'Available',
                          amount: (fiat['availableBalance'] as num).toDouble(),
                          color: AppTheme.success,
                        ),
                      ),
                      Expanded(
                        child: _BalanceTile(
                          label: 'Locked',
                          amount: (fiat['lockedBalance'] as num? ?? 0).toDouble(),
                          color: AppTheme.warning,
                        ),
                      ),
                      Expanded(
                        child: _BalanceTile(
                          label: 'Rewards',
                          amount: (fiat['rewardBalance'] as num? ?? 0).toDouble(),
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // ── Account info ─────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle('Account Info'),
                const SizedBox(height: 12),
                InfoRow(label: 'Phone', value: d['phone'] as String? ?? '—'),
                InfoRow(label: 'Transfer UID', value: d['transferUid'] as String? ?? '—', copyable: true),
                InfoRow(label: 'User ID', value: d['id'] as String, copyable: true),
                InfoRow(
                  label: 'Joined',
                  value: AppFormatters.fromIso(d['createdAt'] as String),
                ),
                InfoRow(
                  label: 'KYC',
                  value: kyc?['status'] as String? ?? 'unverified',
                  valueColor: _kycColor(kyc?['status'] as String?),
                ),
                if (accounts != null && accounts.isNotEmpty)
                  InfoRow(
                    label: 'Virtual Account',
                    value: '${accounts[0]['accountNumber']} · ${accounts[0]['bankName']}',
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Recent transactions ──────────────────────────────────────────
        if (recentTx.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('Recent Transactions'),
                  const SizedBox(height: 8),
                  ...recentTx.map((tx) => _TxRow(tx: tx as Map<String, dynamic>)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),

        // ── Actions ──────────────────────────────────────────────────────
        _SectionTitle('Actions'),
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.arrow_upward_rounded,
          label: 'Manual Credit',
          color: AppTheme.success,
          onTap: _manualCredit,
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.arrow_downward_rounded,
          label: 'Manual Debit',
          color: AppTheme.warning,
          onTap: _manualDebit,
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.manage_accounts_rounded,
          label: 'Change Role (current: ${d['role']})',
          color: AppTheme.accent,
          onTap: _changeRole,
        ),
        if (kyc != null && (kyc['status'] == 'pending'))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _ActionButton(
              icon: Icons.verified_user_outlined,
              label: 'Review KYC',
              color: AppTheme.warning,
              onTap: _reviewKyc,
            ),
          ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: isActive ? Icons.block_rounded : Icons.check_circle_outline,
          label: isActive ? 'Block User' : 'Unblock User',
          color: isActive ? AppTheme.danger : AppTheme.success,
          onTap: _toggleBlock,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Color _kycColor(String? status) {
    switch (status) {
      case 'verified':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      case 'rejected':
        return AppTheme.danger;
      default:
        return AppTheme.textSecondary;
    }
  }
}

// ── KYC Review Dialog ─────────────────────────────────────────────────────────

class _KycReviewDialog extends StatefulWidget {
  const _KycReviewDialog();

  @override
  State<_KycReviewDialog> createState() => _KycReviewDialogState();
}

class _KycReviewDialogState extends State<_KycReviewDialog> {
  String _status = 'verified';
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Review KYC'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatusChoice(
                  label: 'Approve',
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.success,
                  selected: _status == 'verified',
                  onTap: () => setState(() => _status = 'verified'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusChoice(
                  label: 'Reject',
                  icon: Icons.cancel_rounded,
                  color: AppTheme.danger,
                  selected: _status == 'rejected',
                  onTap: () => setState(() => _status = 'rejected'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'status': _status,
            'reason': _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
          }),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _StatusChoice extends StatelessWidget {
  const _StatusChoice({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : AppTheme.divider, width: selected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppTheme.textSecondary, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Local helpers ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
    ),
  );
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.label, required this.amount, required this.color});
  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(AppFormatters.naira(amount),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
    ],
  );
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx});
  final Map<String, dynamic> tx;

  @override
  Widget build(BuildContext context) {
    final isCredit = tx['type'] == 'credit';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            size: 16,
            color: isCredit ? AppTheme.success : AppTheme.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tx['message'] as String? ?? tx['type'] as String,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            AppFormatters.naira((tx['amount'] as num).toDouble()),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isCredit ? AppTheme.success : AppTheme.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondary),
    ),
  );
}