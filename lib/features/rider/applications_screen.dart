import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/empty_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_list.dart';
import 'model.dart';
import 'provider.dart';
import '../../constraints/constants.dart';

class RiderApplicationsScreen extends StatefulWidget {
  const RiderApplicationsScreen({super.key});

  @override
  State<RiderApplicationsScreen> createState() => _RiderApplicationsScreenState();
}

class _RiderApplicationsScreenState extends State<RiderApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RiderProvider>().loadApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<RiderProvider>().loadApplications(silent: true),
          ),
        ],
      ),
      body: Consumer<RiderProvider>(
        builder: (_, p, __) {
          if (p.loading) return const LoadingList();
          if (p.error != null) {
            return ErrorView(
              message: p.error!,
              onRetry: () => p.loadApplications(),
            );
          }
          if (p.applications.isEmpty) {
            return const EmptyView(
              icon: Icons.inbox_rounded,
              message: 'No pending applications',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: p.applications.length,
            itemBuilder: (context, index) {
              final app = p.applications[index];
              return _buildApplicationCard(context, app);
            },
          );
        },
      ),
    );
  }

  Widget _buildApplicationCard(BuildContext context, RiderApplication app) {
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
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(app.photoUrl),
                  backgroundColor: AppTheme.surfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.userName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(app.createdAt),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(app.status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Vehicle Type
            Row(
              children: [
                const Icon(Icons.two_wheeler, color: AppTheme.textSecondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  _formatVehicleType(app.vehicleType),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            if (app.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approve(context, app),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _reject(context, app),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (app.status == 'rejected' && app.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        app.rejectionReason!,
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'approved':
        color = AppTheme.success;
        label = 'Approved';
        break;
      case 'rejected':
        color = AppTheme.danger;
        label = 'Rejected';
        break;
      default:
        color = AppTheme.pending;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _approve(BuildContext context, RiderApplication app) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Approve Application', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Approve ${app.userName} as a rider?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await context.read<RiderProvider>().approve(app.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application approved'),
          backgroundColor: AppTheme.success,
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

  Future<void> _reject(BuildContext context, RiderApplication app) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Reject Application', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reject ${app.userName}\'s application?',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Enter rejection reason...',
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
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await context.read<RiderProvider>().reject(app.id, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application rejected'),
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
