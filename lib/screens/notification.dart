import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/network/dio_client.dart';
import '../core/theme/app_theme.dart';
import '../shared/utils/upload_helpers.dart';

// ── Route options ────────────────────────────────────────────────────────────
// "None" means no deep-link; "Custom…" shows a free-text field below the
// dropdown. All others map directly to their go_router path.
const List<_RouteOption> _kRouteOptions = [
  _RouteOption('None', null),
  _RouteOption('Wallet', '/wallet'),
  _RouteOption('Store', '/store'),
  _RouteOption('Orders', '/orders'),
  _RouteOption('Settings', '/settings'),
  _RouteOption('Custom…', '__custom__'),
];

class _RouteOption {
  final String label;
  final String? value; // null = no link; '__custom__' = show text field
  const _RouteOption(this.label, this.value);
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form state
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _customRouteCtrl = TextEditingController();

  String? _imageUrl;          // filled after upload
  XFile? _pickedFile;         // for thumbnail preview
  bool _imageUploading = false;

  _RouteOption _selectedRoute = _kRouteOptions.first; // 'None'
  bool _saveToFirestore = true;   // "Add to Amril Official chat"
  String _audience = 'users';     // 'users' | 'vendors' | 'both'

  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _customRouteCtrl.dispose();
    super.dispose();
  }

  // ── Image upload ──────────────────────────────────────────────────────────
  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    setState(() {
      _pickedFile = file;
      _imageUploading = true;
      _imageUrl = null;
    });

    try {
      final multipart = await dioMultipartFromXFile(file);
      final formData = dio.FormData.fromMap({'image': multipart});
      final resp = await DioClient.postMultipart(
        '/chat/official/broadcast/upload-image',
        formData,
      );
      setState(() {
        _imageUrl = resp['imageUrl'] as String?;
        _imageUploading = false;
      });
    } catch (e) {
      setState(() => _imageUploading = false);
      _showSnack('Image upload failed: $e', isError: true);
    }
  }

  void _removeImage() => setState(() {
        _imageUrl = null;
        _pickedFile = null;
      });

  // ── Send broadcast ────────────────────────────────────────────────────────
  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUploading) {
      _showSnack('Wait for image upload to finish', isError: true);
      return;
    }

    final route = _resolvedRoute();

    setState(() => _sending = true);
    try {
      await DioClient.post('/chat/official/broadcast', data: {
        'title': _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        if (_imageUrl != null) 'imageUrl': _imageUrl,
        if (route != null) 'route': route,
        'audience': _audience,
        'saveToFirestore': _saveToFirestore,
      });

      _showSnack('Broadcast sent ✓');
      _reset();
    } catch (e) {
      _showSnack('Failed to send: $e', isError: true);
    } finally {
      setState(() => _sending = false);
    }
  }

  String? _resolvedRoute() {
    if (_selectedRoute.value == null) return null;
    if (_selectedRoute.value == '__custom__') {
      final v = _customRouteCtrl.text.trim();
      return v.isEmpty ? null : v;
    }
    return _selectedRoute.value;
  }

  void _reset() {
    _titleCtrl.clear();
    _messageCtrl.clear();
    _customRouteCtrl.clear();
    setState(() {
      _imageUrl = null;
      _pickedFile = null;
      _selectedRoute = _kRouteOptions.first;
      _saveToFirestore = true;
      _audience = 'users';
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF0D9488), Color(0xFF0F172A), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
              children: [
                _SectionHeader('Broadcast'),
                const SizedBox(height: 20),

                // ── Audience ──────────────────────────────────────────────
                _label('Audience'),
                const SizedBox(height: 8),
                _AudienceRadio(
                  value: _audience,
                  onChanged: (v) => setState(() => _audience = v),
                ),
                const SizedBox(height: 20),

                // ── Title ─────────────────────────────────────────────────
                _label('Title (optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: _inputDec(
                    'e.g. "New Feature" or leave blank',
                    hint: 'Tip: use <username> to personalise (targeted only)',
                  ),
                ),
                const SizedBox(height: 16),

                // ── Message ───────────────────────────────────────────────
                _label('Message *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  maxLines: 4,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Message is required' : null,
                  decoration: _inputDec(
                    'What do you want to say?',
                    hint: 'Tip: use <username> to personalise (targeted only)',
                  ),
                ),
                const SizedBox(height: 20),

                // ── Image upload ──────────────────────────────────────────
                _label('Image (optional)'),
                const SizedBox(height: 8),
                _ImagePickerCard(
                  pickedFile: _pickedFile,
                  imageUrl: _imageUrl,
                  uploading: _imageUploading,
                  onPick: _pickAndUpload,
                  onRemove: _removeImage,
                ),
                const SizedBox(height: 20),

                // ── Route picker ──────────────────────────────────────────
                _label('Deep-link (optional)'),
                const SizedBox(height: 8),
                DropdownButtonFormField<_RouteOption>(
                  value: _selectedRoute,
                  dropdownColor: AppTheme.surface,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: _inputDec(''),
                  items: _kRouteOptions
                      .map((o) => DropdownMenuItem(
                            value: o,
                            child: Text(o.label),
                          ))
                      .toList(),
                  onChanged: (o) {
                    if (o != null) setState(() => _selectedRoute = o);
                  },
                ),
                if (_selectedRoute.value == '__custom__') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customRouteCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: _inputDec('/order/<id> or /vendor/<id>'),
                  ),
                ],
                const SizedBox(height: 20),

                // ── Firestore toggle ──────────────────────────────────────
                _CheckboxRow(
                  label: 'Add to Amril Official chat',
                  subtitle: 'Unchecked = FCM push only (no chat history)',
                  value: _saveToFirestore,
                  onChanged: (v) => setState(() => _saveToFirestore = v ?? true),
                ),
                const SizedBox(height: 32),

                // ── Send button ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text('Send Broadcast'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String placeholder, {String? hint}) {
    return InputDecoration(
      hintText: placeholder,
      hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      helperText: hint,
      helperStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      );
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _AudienceRadio extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _AudienceRadio({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: RadioGroup<String>(
        groupValue: value,
        onChanged: (v) => onChanged(v!),
        child: Column(
          children: [
            RadioListTile<String>(
              dense: true,
              value: 'users',
              title: const Text('All users',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            ),
            RadioListTile<String>(
              dense: true,
              value: 'vendors',
              title: const Text('All vendors',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            ),
            RadioListTile<String>(
              dense: true,
              value: 'both',
              title: const Text('Both',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final XFile? pickedFile;
  final String? imageUrl;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImagePickerCard({
    required this.pickedFile,
    required this.imageUrl,
    required this.uploading,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (pickedFile == null) {
      return OutlinedButton.icon(
        onPressed: onPick,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.divider),
          foregroundColor: AppTheme.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 0),
        ),
        icon: const Icon(Icons.image_outlined, size: 18),
        label: const Text('Pick image from gallery'),
      );
    }

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Stack(
        children: [
          // Thumbnail (web-safe: use Image.network once URL lands; show
          // a grey placeholder while uploading since XFile.path is a blob: URL
          // and Image.file crashes on web).
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover)
                  : const DecoratedBox(
                      decoration: BoxDecoration(color: AppTheme.surfaceVariant),
                    ),
            ),
          ),
          // Upload spinner
          if (uploading)
            const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2,
              ),
            ),
          // Remove button
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          // Status chip
          if (!uploading)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: imageUrl != null ? AppTheme.success : AppTheme.warning,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  imageUrl != null ? 'Uploaded ✓' : 'Uploading…',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckboxRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primary,
        checkColor: Colors.black,
        title: Text(label,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
