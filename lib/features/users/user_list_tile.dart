import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

import 'model.dart';

class UserListTile extends StatelessWidget {
  const UserListTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  final AdminUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _Avatar(name: user.name, url: user.avatarUrl, isVerified: user.isVerified),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            _RoleBadge(role: user.role),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              user.email,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _KycChip(status: user.kycStatus),
                const SizedBox(width: 6),
                if (!user.active) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'BLOCKED',
                      style: TextStyle(
                        color: AppTheme.danger,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (user.availableBalance != null)
              Text(
                AppFormatters.naira(user.availableBalance!),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              AppFormatters.timeAgo(user.createdAt),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.url, required this.isVerified});

  final String name;
  final String? url;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.accent.withOpacity(0.12),
          backgroundImage:
          (url != null && url!.isNotEmpty) ? CachedNetworkImageProvider(url!) : null,
          child: (url == null || url!.isEmpty)
              ? Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          )
              : null,
        ),
        if (isVerified)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, color: AppTheme.accent, size: 12),
            ),
          ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  Color get _color {
    switch (role) {
      case 'admin':
        return AppTheme.accent;
      case 'vendor':
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (role == 'user') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _KycChip extends StatelessWidget {
  const _KycChip({this.status});

  final String? status;

  Color get _color {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'KYC ${(status ?? 'unverified').toUpperCase()}',
        style: TextStyle(
          color: _color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}