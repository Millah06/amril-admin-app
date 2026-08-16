import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import 'provider.dart';

/// Admin broadcast screen — sends a real FCM topic push to every signed-in
/// device on the `all_users` topic, AND appends the message to the
/// official_broadcast Firestore collection so it appears in the in-app chat.
///
/// Fields:
///   title?      — headline (shown bold in the notification + chat card)
///   message*    — body (required)
///   imageUrl?   — optional image URL embedded in both push + chat card
///   route?      — go_router path the app navigates to on tap
///                 (e.g. /store/<id>, /order/<id>, /wallet)
class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _routeCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _imageCtrl.dispose();
    _routeCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(BroadcastProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await provider.send(
      title: _titleCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
      imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
      route: _routeCtrl.text.trim().isEmpty ? null : _routeCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.success,
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Broadcast sent${provider.lastFcmId != null ? ' — ${provider.lastFcmId!.substring(0, 12)}…' : ''}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
      // Clear the form so the admin doesn't accidentally re-send.
      _titleCtrl.clear();
      _messageCtrl.clear();
      _imageCtrl.clear();
      _routeCtrl.clear();
      provider.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provider is injected by ShellScreen — consume it directly.
    final provider = context.watch<BroadcastProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast')),
      body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _HeroCard(),
                const SizedBox(height: 24),

                // ── Title ─────────────────────────────────────────────────
                _FieldLabel('Title', optional: true),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 🔔 New feature available',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Message ────────────────────────────────────────────────
                _FieldLabel('Message', optional: false),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _messageCtrl,
                  maxLines: 5,
                  minLines: 3,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'What do you want to tell every user?',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 64),
                      child: Icon(Icons.message_outlined),
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Message is required' : null,
                ),
                const SizedBox(height: 18),

                // ── Image URL ──────────────────────────────────────────────
                _FieldLabel('Image URL', optional: true),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _imageCtrl,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'https://… (shown in push + chat)',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final uri = Uri.tryParse(v.trim());
                    if (uri == null || !uri.hasScheme) return 'Enter a valid URL';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── Deep-link route ────────────────────────────────────────
                _FieldLabel('Deep-link route', optional: true),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _routeCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: '/store/<id> · /order/<id> · /wallet',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Users who tap the notification navigate here inside the app.',
                  style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.8),
                      fontSize: 12),
                ),

                if (provider.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.danger.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.danger, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: const TextStyle(
                                color: AppTheme.danger, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.sending ? null : () => _send(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.background,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: provider.sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.background),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      provider.sending ? 'Sending…' : 'Send to all users',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
  }
}

// ── Hero explainer card ───────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign_rounded,
                color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Broadcast to all users',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
                SizedBox(height: 5),
                Text(
                  'Sends a real push notification to every signed-in device '
                  'and adds the message to the Amril Official chat channel.',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12.5, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field label row ───────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool optional;
  const _FieldLabel(this.label, {required this.optional});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13.5)),
        const SizedBox(width: 6),
        if (optional)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('optional',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500)),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('required',
                style: TextStyle(
                    color: AppTheme.danger,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
