import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../models/appeal_model.dart';

/// A self-contained chat widget that:
///   - Streams messages from Firestore `orderChats/{chatId}/messages`
///   - Renders sent (admin/support) messages on the right, received on left
///   - Calls [onSend] when the user submits a message (your provider handles POST)
///
/// Used in:
///   - Appeal detail screen  (chatId = orderId)
///   - Support chat screen   (chatId = supportTicketId or userId)
class OrderChatView extends StatefulWidget {
  const OrderChatView({
    super.key,
    required this.chatId,
    required this.onSend,
    this.isSending = false,
    this.senderLabel = 'Support',
    this.inputHint = 'Type a message…',
  });

  /// Firestore document ID under `orderChats/`
  final String chatId;

  /// Called with the typed message when the user hits send.
  /// The parent (provider) is responsible for the actual POST.
  final Future<void> Function(String message) onSend;

  /// Shows a spinner on the send button while true.
  final bool isSending;

  /// Label shown on outgoing bubble (e.g. "Support", "Admin")
  final String senderLabel;

  final String inputHint;

  @override
  State<OrderChatView> createState() => _OrderChatViewState();
}

class _OrderChatViewState extends State<OrderChatView> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || widget.isSending) return;
    _ctrl.clear();
    _focusNode.requestFocus();
    await widget.onSend(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Message stream ────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orderChats')
                .doc(widget.chatId)
                .collection('messages')
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Could not load messages',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet.\nBe the first to write.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                );
              }

              // Auto-scroll when new messages arrive
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final doc = docs[i];
                  final msg = ChatMessage.fromFirestore(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  );
                  return _MessageBubble(
                    message: msg,
                    senderLabel: widget.senderLabel,
                  );
                },
              );
            },
          ),
        ),

        // ── Input bar ─────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: AppTheme.cardBg,
            border: Border(top: BorderSide(color: AppTheme.divider)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: widget.inputHint,
                      hintStyle: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14),
                      filled: true,
                      fillColor: AppTheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppTheme.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppTheme.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: AppTheme.accent, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  child: widget.isSending
                      ? const SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.accent),
                      ),
                    ),
                  )
                      : IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                    color: AppTheme.accent,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.accent.withOpacity(0.1),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.senderLabel});

  final ChatMessage message;
  final String senderLabel;

  @override
  Widget build(BuildContext context) {
    final isOutgoing = message.isFromAdmin;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
        isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender label
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              isOutgoing ? senderLabel : message.senderName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isOutgoing ? AppTheme.accent : AppTheme.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          // Bubble
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: message.message));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message copied'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isOutgoing
                    ? AppTheme.accent
                    : AppTheme.cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isOutgoing ? 16 : 4),
                  bottomRight: Radius.circular(isOutgoing ? 4 : 16),
                ),
                border: isOutgoing
                    ? null
                    : Border.all(color: AppTheme.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  fontSize: 14,
                  color: isOutgoing ? Colors.white : AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              AppFormatters.time(message.createdAt),
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}