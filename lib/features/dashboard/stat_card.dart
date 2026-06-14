import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A single metric tile shown on the dashboard grid.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.iconBg,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBg;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBg ?? AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: iconColor ?? AppTheme.accent,
                    ),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width wide card for balance overview, etc.
class WideStatCard extends StatelessWidget {
  const WideStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.children,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color ?? AppTheme.accent),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color ?? AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            if (children != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...children!,
            ],
          ],
        ),
      ),
    );
  }
}