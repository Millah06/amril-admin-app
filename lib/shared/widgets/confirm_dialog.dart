import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Confirm Dialog
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a confirmation dialog and returns true if the user confirmed.
Future<bool> showConfirmDialog(
    BuildContext context, {
      required String title,
      required String message,
      String confirmLabel = 'Confirm',
      String cancelLabel = 'Cancel',
      bool isDestructive = false,
    }) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          style: isDestructive
              ? ElevatedButton.styleFrom(backgroundColor: AppTheme.danger)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ─────────────────────────────────────────────────────────────────────────────
// InfoRow — used in detail screens
// ─────────────────────────────────────────────────────────────────────────────

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.copyable = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool copyable;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (copyable) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Icon(Icons.copy, size: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}