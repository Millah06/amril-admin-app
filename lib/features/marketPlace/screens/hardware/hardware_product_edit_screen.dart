import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/image_editor.dart';
import '../../models/hardware_model.dart';
import '../../providers/hardware_provider.dart';

/// Dedicated create/edit screen for a hardware product (§2.1).
/// NOT a dialog — full fields, image upload, repeatable bullet rows, preloaded
/// on edit, Save with validation.
class HardwareProductEditScreen extends StatefulWidget {
  const HardwareProductEditScreen({super.key, this.product});

  /// Null = create; non-null = edit (fields preloaded).
  final HwProduct? product;

  @override
  State<HardwareProductEditScreen> createState() =>
      _HardwareProductEditScreenState();
}

class _HardwareProductEditScreenState extends State<HardwareProductEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _upcharge;
  late final TextEditingController _sort;

  late String _tier;
  late String _category;
  late bool _active;

  // Bullet points as a proper repeatable list (each its own row), NOT a textarea.
  late List<TextEditingController> _bullets;

  // Image state driven by AppImagePicker.
  late List<String> _keptImageUrls;
  List<XFile> _newImages = [];

  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: (p?.priceNaira ?? 0).toString());
    _upcharge =
        TextEditingController(text: p?.brandingUpchargeNaira?.toString() ?? '');
    _sort = TextEditingController(text: (p?.sortOrder ?? 0).toString());
    _tier = p?.tier ?? 'budget';
    _category = p?.category ?? 'bundle';
    _active = p?.isActive ?? true;
    _bullets = (p?.bulletPoints.isNotEmpty ?? false)
        ? p!.bulletPoints.map((b) => TextEditingController(text: b)).toList()
        : [TextEditingController()];
    _keptImageUrls = List.from(p?.images ?? const []);
  }

  @override
  void dispose() {
    for (final c in [_name, _sku, _desc, _price, _upcharge, _sort]) {
      c.dispose();
    }
    for (final b in _bullets) {
      b.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final bullets = _bullets
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'sku': _sku.text.trim(),
      'tier': _tier,
      'category': _category,
      'description': _desc.text.trim(),
      'priceNaira': int.tryParse(_price.text.trim()) ?? 0,
      // Empty → 0 (free branding), not null — keeps the app's `+₦X` math simple.
      'brandingUpchargeNaira': int.tryParse(_upcharge.text.trim()) ?? 0,
      'bulletPoints': bullets,
      'sortOrder': int.tryParse(_sort.text.trim()) ?? 0,
      'isActive': _active,
    };

    setState(() => _saving = true);
    final err = await context.read<HardwareProvider>().saveProductWithImages(
          id: widget.product?.id,
          body: body,
          keptImageUrls: _keptImageUrls,
          newImages: _newImages,
        );
    if (!mounted) return;
    setState(() => _saving = false);

    if (err == null) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Product updated' : 'Product created'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit product' : 'New product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _sectionCard(
              icon: Icons.badge_outlined,
              title: 'Basics',
              children: [
                _text(_name, 'Name', required: true),
                const SizedBox(height: 12),
                _text(_sku, 'SKU', required: true),
                const SizedBox(height: 16),
                _label('Tier'),
                const SizedBox(height: 8),
                _segmented(
                  value: _tier,
                  options: const {
                    'budget': 'Budget',
                    'premium': 'Premium',
                    'kiosk': 'Kiosk',
                    'tab': 'Tab',
                  },
                  onChanged: (v) => setState(() => _tier = v),
                ),
                const SizedBox(height: 16),
                _label('Category'),
                const SizedBox(height: 4),
                const Text(
                  'Bundles join a per-product MOQ batch. Add-ons ship on-demand.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                _segmented(
                  value: _category,
                  options: const {'bundle': 'Bundle', 'addon': 'Add-on'},
                  onChanged: (v) => setState(() => _category = v),
                ),
              ],
            ),
            _sectionCard(
              icon: Icons.image_outlined,
              title: 'Images',
              children: [
                AppImagePicker(
                  existingImages: _keptImageUrls,
                  onChanged: (kept, added) {
                    _keptImageUrls = kept;
                    _newImages = added;
                  },
                ),
              ],
            ),
            _sectionCard(
              icon: Icons.notes_outlined,
              title: 'Details',
              children: [
                _text(_desc, 'Description', lines: 3),
                const SizedBox(height: 12),
                _text(_price, 'Price (₦)', number: true, required: true),
                const SizedBox(height: 12),
                _text(_upcharge,
                    'Branding upcharge (₦, per unit — 0 = free branding)',
                    number: true),
                const SizedBox(height: 12),
                _text(_sort, 'Sort order', number: true),
              ],
            ),
            _sectionCard(
              icon: Icons.checklist_rounded,
              title: 'Bullet points',
              subtitle: 'Why it matters — one point per row',
              children: [_bulletList()],
            ),
            _sectionCard(
              icon: Icons.toggle_on_outlined,
              title: 'Visibility',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppTheme.primary,
                  title: const Text('Active',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  subtitle: const Text('Shown in the vendor catalog',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _saveBar(),
    );
  }

  // ── Bullet points repeatable list ──
  Widget _bulletList() {
    return Column(
      children: [
        for (int i = 0; i < _bullets.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 7, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _bullets[i],
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Benefit ${i + 1}',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppTheme.danger),
                  onPressed: _bullets.length == 1
                      ? null
                      : () => setState(() {
                            _bullets.removeAt(i).dispose();
                          }),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () =>
                setState(() => _bullets.add(TextEditingController())),
            icon: const Icon(Icons.add, color: AppTheme.primary, size: 18),
            label: const Text('Add bullet',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ),
      ],
    );
  }

  // ── Save bar ──
  Widget _saveBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving
                ? 'Saving…'
                : (_isEdit ? 'Save changes' : 'Create product')),
          ),
        ),
      ),
    );
  }

  // ── Small helpers ──
  Widget _sectionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600));

  Widget _text(
    TextEditingController c,
    String label, {
    bool number = false,
    int lines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: c,
      maxLines: lines,
      style: const TextStyle(color: AppTheme.textPrimary),
      keyboardType: number ? TextInputType.number : TextInputType.text,
      inputFormatters:
          number ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
    );
  }

  Widget _segmented({
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return SegmentedButton<String>(
      style: SegmentedButton.styleFrom(
        backgroundColor: AppTheme.surfaceVariant,
        selectedBackgroundColor: AppTheme.primary.withValues(alpha: 0.2),
        selectedForegroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textSecondary,
        side: const BorderSide(color: AppTheme.divider),
      ),
      segments: options.entries
          .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
          .toList(),
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
