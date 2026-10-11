import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/empty_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_list.dart';
import 'model.dart';
import 'provider.dart';
import '../../constraints/constants.dart';

class RidersScreen extends StatefulWidget {
  const RidersScreen({super.key});

  @override
  State<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends State<RidersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RiderProvider>().loadRiders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Riders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<RiderProvider>().loadRiders(silent: true),
          ),
        ],
      ),
      body: Consumer<RiderProvider>(
        builder: (_, p, __) {
          if (p.loading) return const LoadingList();
          if (p.error != null) {
            return ErrorView(
              message: p.error!,
              onRetry: () => p.loadRiders(),
            );
          }
          if (p.riders.isEmpty) {
            return const EmptyView(
              icon: Icons.two_wheeler,
              message: 'No active riders',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: p.riders.length,
            itemBuilder: (context, index) {
              final rider = p.riders[index];
              return _buildRiderCard(context, rider);
            },
          );
        },
      ),
    );
  }

  Widget _buildRiderCard(BuildContext context, Rider rider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.surfaceVariant,
                      child: Text(
                        rider.userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (rider.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.cardBg, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider.userName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            rider.isOnline ? Icons.circle : Icons.circle_outlined,
                            size: 12,
                            color: rider.isOnline ? AppTheme.success : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rider.isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: rider.isOnline ? AppTheme.success : AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatVehicleType(rider.vehicleType),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  color: AppTheme.textSecondary,
                  onPressed: () => _showActions(context, rider),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStat(
                    'Rating',
                    '${rider.rating.toStringAsFixed(1)} ⭐',
                    Icons.star_rounded,
                  ),
                ),
                Expanded(
                  child: _buildStat(
                    'Deliveries',
                    rider.totalDeliveries.toString(),
                    Icons.local_shipping_rounded,
                  ),
                ),
                Expanded(
                  child: _buildStat(
                    'Earnings',
                    '$kNaira${kFormatterNo.format(rider.totalEarnings)}',
                    Icons.account_balance_wallet_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatVehicleType(String type) {
    switch (type) {
      case 'motorcycle':
        return 'Motorcycle';
      case 'bicycle':
        return 'Bicycle';
      case 'car':
        return 'Car';
      default:
        return type;
    }
  }

  Future<void> _showActions(BuildContext context, Rider rider) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: AppTheme.danger),
              title: const Text('Suspend Rider', style: TextStyle(color: AppTheme.danger)),
              onTap: () {
                Navigator.pop(context);
                _suspendRider(context, rider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
              title: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _suspendRider(BuildContext context, Rider rider) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Suspend Rider', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Suspend ${rider.userName}?',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Enter suspension reason...',
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await context.read<RiderProvider>().suspend(rider.id, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rider suspended'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }
}
