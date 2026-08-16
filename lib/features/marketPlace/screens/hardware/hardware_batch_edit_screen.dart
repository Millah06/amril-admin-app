import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/hardware_model.dart';
import '../../providers/hardware_provider.dart';

/// Dedicated create/edit screen for a hardware batch (§3).
/// Batches are per-PRODUCT: create picks an active bundle product (tier is
/// derived, shown read-only); edit shows the linked product immutable. Legacy
/// tier-wide batches (null productId) stay editable but are labeled.
class HardwareBatchEditScreen extends StatefulWidget {
  const HardwareBatchEditScreen({super.key, this.batch});

  final HwBatch? batch;

  @override
  State<HardwareBatchEditScreen> createState() =>
      _HardwareBatchEditScreenState();
}

class _HardwareBatchEditScreenState extends State<HardwareBatchEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _moq;
  late final TextEditingController _eta;
  String? _productId;
  late String _state;
  bool _saving = false;

  bool get _isEdit => widget.batch != null;

  @override
  void initState() {
    super.initState();
    final b = widget.batch;
    _moq = TextEditingController(text: (b?.moqTarget ?? 500).toString());
    _eta = TextEditingController(text: b?.etaNote ?? '');
    _productId = b?.productId;
    _state = b?.state ?? 'collecting';
    // Ensure the picker has products even when this screen is opened before
    // the hardware tab finished its first load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<HardwareProvider>();
      if (p.products.isEmpty && !p.loading) p.loadProducts();
    });
  }

  @override
  void dispose() {
    _moq.dispose();
    _eta.dispose();
    super.dispose();
  }

  List<HwProduct> _pickableProducts(HardwareProvider p) =>
      p.products.where((pr) => pr.isBundle && pr.isActive).toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdit && _productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pick a product for this batch'),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final body = <String, dynamic>{
      if (!_isEdit) 'productId': _productId,
      'moqTarget': int.tryParse(_moq.text.trim()) ?? 500,
      if (_isEdit) 'state': _state,
      'etaNote': _eta.text.trim(),
    };
    setState(() => _saving = true);
    final err = await context
        .read<HardwareProvider>()
        .saveBatch(body, id: widget.batch?.id);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err == null) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Batch updated' : 'Batch created'),
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
    final b = widget.batch;
    final stateChanged = _isEdit && b != null && _state != b.state;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit batch' : 'New batch')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _card(
              icon: Icons.inventory_2_outlined,
              title: 'Batch',
              children: [
                if (!_isEdit) ...[
                  _label('Product'),
                  const SizedBox(height: 4),
                  const Text(
                    'Each batch collects orders for ONE bundle product. '
                    'Add-ons ship on-demand and never batch.',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Consumer<HardwareProvider>(
                    builder: (_, p, __) {
                      final products = _pickableProducts(p);
                      if (products.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    AppTheme.warning.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'No active bundle products — create one first.',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        );
                      }
                      // Guard against a stale selection (product deactivated
                      // between loads).
                      final valid =
                          products.any((pr) => pr.id == _productId);
                      return DropdownButtonFormField<String>(
                        initialValue: valid ? _productId : null,
                        dropdownColor: AppTheme.surface,
                        decoration:
                            const InputDecoration(hintText: 'Pick a product'),
                        items: products
                            .map((pr) => DropdownMenuItem(
                                  value: pr.id,
                                  child: Text(
                                    '${pr.name} · ${pr.tier}',
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _productId = v),
                        validator: (v) =>
                            v == null ? 'Pick a product' : null,
                      );
                    },
                  ),
                  Consumer<HardwareProvider>(
                    builder: (_, p, __) {
                      final sel = p.products
                          .where((pr) => pr.id == _productId)
                          .toList();
                      if (sel.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Tier: ${sel.first.tier} (derived from the product)',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (_isEdit) ...[
                  _label('Product'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          b!.isLegacy
                              ? Icons.history_rounded
                              : Icons.inventory_2_outlined,
                          size: 18,
                          color: b.isLegacy
                              ? AppTheme.warning
                              : AppTheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            b.isLegacy
                                ? 'Legacy (tier-wide) · ${b.tier}'
                                : '${b.productName ?? 'Product'} · ${b.tier}',
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (b.isLegacy)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Legacy batches have no linked product — new orders '
                        'won\'t join them.',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _moq,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'MOQ target'),
                  validator: (v) =>
                      (int.tryParse(v?.trim() ?? '') ?? 0) <= 0
                          ? 'Enter a target > 0'
                          : null,
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 16),
                  _label('State'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _state,
                    dropdownColor: AppTheme.surface,
                    decoration: const InputDecoration(),
                    items: hwBatchStates
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _state = v ?? 'collecting'),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _eta,
                  maxLines: 2,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'ETA note'),
                ),
              ],
            ),
            if (_isEdit && b != null)
              _card(
                icon: Icons.stacked_bar_chart_rounded,
                title: 'Progress',
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${b.reservedCount} reserved + ${b.paidCount} paid',
                          style: const TextStyle(
                              color: AppTheme.textSecondary)),
                      Text('${b.progressCount} / ${b.moqTarget}',
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: b.progress,
                      minHeight: 8,
                      backgroundColor: AppTheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(b.progress >= 1
                          ? AppTheme.success
                          : AppTheme.primary),
                    ),
                  ),
                ],
              ),
            if (stateChanged)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Moving this batch to "$_state" will auto-advance member '
                        'orders that are behind. Delivered/cancelled orders are '
                        'left untouched.',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
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
                  : (_isEdit ? 'Save changes' : 'Create batch')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600));

  Widget _card({
    required IconData icon,
    required String title,
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
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
