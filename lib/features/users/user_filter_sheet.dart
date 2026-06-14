import 'package:admin_panel/features/users/provider.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';


/// Bottom sheet for filtering the user list.
/// Caller receives the new [UserFilter] via [onApply].
class UserFilterSheet extends StatefulWidget {
  const UserFilterSheet({super.key, required this.current, required this.onApply});

  final UserFilter current;
  final ValueChanged<UserFilter> onApply;

  @override
  State<UserFilterSheet> createState() => _UserFilterSheetState();
}

class _UserFilterSheetState extends State<UserFilterSheet> {
  late String? _role;
  late bool? _active;
  late String? _kycStatus;

  @override
  void initState() {
    super.initState();
    _role = widget.current.role;
    _active = widget.current.active;
    _kycStatus = widget.current.kycStatus;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Filter Users',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _role = null;
                    _active = null;
                    _kycStatus = null;
                  }),
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Role
            const _FilterLabel('Role'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['user', 'vendor', 'admin'].map((r) {
                final selected = _role == r;
                return FilterChip(
                  label: Text(r),
                  selected: selected,
                  onSelected: (_) => setState(() => _role = selected ? null : r),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Status
            const _FilterLabel('Account Status'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _StatusChip(
                  label: 'Active',
                  selected: _active == true,
                  onTap: () => setState(() => _active = _active == true ? null : true),
                ),
                _StatusChip(
                  label: 'Blocked',
                  selected: _active == false,
                  color: AppTheme.danger,
                  onTap: () => setState(() => _active = _active == false ? null : false),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // KYC status
            const _FilterLabel('KYC Status'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['unverified', 'pending', 'verified', 'rejected'].map((s) {
                final selected = _kycStatus == s;
                return FilterChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (_) => setState(() => _kycStatus = selected ? null : s),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApply(
                    UserFilter(
                      role: _role,
                      active: _active,
                      kycStatus: _kycStatus,
                      search: widget.current.search,
                    ),
                  );
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
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
      letterSpacing: 0.3,
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.success;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.12) : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : AppTheme.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? c : AppTheme.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}