import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

/// Admin screen to configure rider bonus system
/// Endpoint: GET/PATCH /admin/economics/config
class BonusConfigScreen extends StatefulWidget {
  const BonusConfigScreen({super.key});

  @override
  State<BonusConfigScreen> createState() => _BonusConfigScreenState();
}

class _BonusConfigScreenState extends State<BonusConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  // Config values
  bool _bonusEnabled = true;
  final _bonus50Controller = TextEditingController();
  final _bonus100Controller = TextEditingController();
  final _bonus150Controller = TextEditingController();
  final _bonus200Controller = TextEditingController();
  final _platformFeeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _apiService.get('/admin/economics/config');
      final config = res['config'] as Map<String, dynamic>;

      setState(() {
        _bonusEnabled = config['bonusEnabled'] == true;
        _bonus50Controller.text = config['bonus50Deliveries']?.toString() ?? '5000';
        _bonus100Controller.text = config['bonus100Deliveries']?.toString() ?? '15000';
        _bonus150Controller.text = config['bonus150Deliveries']?.toString() ?? '30000';
        _bonus200Controller.text = config['bonus200Deliveries']?.toString() ?? '50000';
        _platformFeeController.text = config['riderPlatformFeePercent']?.toString() ?? '15';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _apiService.patch('/admin/economics/config', data: {
        'bonusEnabled': _bonusEnabled,
        'bonus50Deliveries': int.parse(_bonus50Controller.text),
        'bonus100Deliveries': int.parse(_bonus100Controller.text),
        'bonus150Deliveries': int.parse(_bonus150Controller.text),
        'bonus200Deliveries': int.parse(_bonus200Controller.text),
        'riderPlatformFeePercent': double.parse(_platformFeeController.text),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Configuration saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _bonus50Controller.dispose();
    _bonus100Controller.dispose();
    _bonus150Controller.dispose();
    _bonus200Controller.dispose();
    _platformFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Bonus Configuration'),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Bonus System Toggle
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bonus System',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enable or disable monthly performance bonuses for riders',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              value: _bonusEnabled,
                              onChanged: (value) {
                                setState(() => _bonusEnabled = value);
                              },
                              title: Text(
                                _bonusEnabled ? 'Bonus System Enabled' : 'Bonus System Disabled',
                                style: TextStyle(
                                  color: _bonusEnabled ? Colors.green : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                _bonusEnabled
                                    ? 'Riders can earn bonuses based on monthly deliveries'
                                    : 'Riders will not see or earn bonuses',
                              ),
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bonus Tiers
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bonus Tiers',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Set bonus amounts for each delivery milestone',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            _buildBonusTierField(
                              controller: _bonus50Controller,
                              label: '50 Deliveries Bonus',
                              icon: Icons.local_shipping,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 16),
                            _buildBonusTierField(
                              controller: _bonus100Controller,
                              label: '100 Deliveries Bonus',
                              icon: Icons.local_shipping,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            _buildBonusTierField(
                              controller: _bonus150Controller,
                              label: '150 Deliveries Bonus',
                              icon: Icons.local_shipping,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            _buildBonusTierField(
                              controller: _bonus200Controller,
                              label: '200 Deliveries Bonus',
                              icon: Icons.local_shipping,
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Platform Fee
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Platform Fee',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Percentage of delivery fee kept by platform (0-50%)',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _platformFeeController,
                              decoration: InputDecoration(
                                labelText: 'Platform Fee Percentage',
                                hintText: '15',
                                suffixText: '%',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.percent),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final num = double.tryParse(value);
                                if (num == null) return 'Invalid number';
                                if (num < 0 || num > 50) return 'Must be between 0 and 50';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveConfig,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Configuration',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBonusTierField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: '5000',
        prefixText: '₦',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: Icon(icon, color: color),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        final num = int.tryParse(value);
        if (num == null) return 'Invalid number';
        if (num < 0) return 'Must be positive';
        return null;
      },
    );
  }
}

