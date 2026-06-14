import 'package:admin_panel/features/transaction/screen.dart';
import 'package:admin_panel/features/users/users_screen.dart';
import 'package:admin_panel/screens/main/market_place.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';


import 'analytics/screen.dart';
import 'dashboard/screen.dart';
import 'marketPlace/shell.dart';

/// The root scaffold with 4-tab bottom navigation.
/// Each tab preserves its own navigation stack via [IndexedStack].
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _TabItem(icon: Icons.people_alt_rounded, label: 'Users'),
    _TabItem(icon: Icons.receipt_long_rounded, label: 'Transactions'),
    _TabItem(icon: Icons.storefront_rounded, label: 'Market'),
    _TabItem(icon: Icons.bar_chart_rounded, label: 'Analytics'),
  ];

  static const _screens = [
    DashboardScreen(),
    UsersScreen(),
    TransactionsScreen(),
    MarketPlaceShell(),
    AnalyticsScreen(),
  ];

  /// Double-tap on current tab to scroll to top (handled inside each screen),
  /// or tap to switch.
  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          // color:  Color(0xFF334155),
          border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
        ),
        child: BottomNavigationBar(

          // backgroundColor:  Color(0xFF334155),
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: _tabs
              .map(
                (t) => BottomNavigationBarItem(
              icon: Icon(t.icon),
              label: t.label,
            ),
          )
              .toList(),
        ),
      ),
      // Floating sign-out accessible from anywhere
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.small(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        tooltip: 'Sign out',
        onPressed: () => _confirmSignOut(context),
        child: const Icon(Icons.logout_rounded, size: 18),
      )
          : null,
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      print("CURRENT USER: ${FirebaseAuth.instance.currentUser}");
      FirebaseAuth.instance.signOut();
      final share = await SharedPreferences.getInstance();
      share.setBool('isSetupDone', false);
      // context.read<AuthProvider>().signOut();
    }
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}