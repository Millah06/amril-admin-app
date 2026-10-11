import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'applications_screen.dart';
import 'riders_screen.dart';

class RiderShell extends StatefulWidget {
  const RiderShell({super.key});

  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Management'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Applications'),
            Tab(text: 'Active Riders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          RiderApplicationsScreen(),
          RidersScreen(),
        ],
      ),
    );
  }
}
