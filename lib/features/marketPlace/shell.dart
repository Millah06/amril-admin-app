import 'package:admin_panel/features/marketPlace/service/appeal_service.dart';
import 'package:admin_panel/features/marketPlace/service/config_service.dart';
import 'package:admin_panel/features/marketPlace/service/dashboard_services.dart';
import 'package:admin_panel/features/marketPlace/service/vendor_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import './providers/appeal_provider.dart';
import './providers/config_provider.dart';
import './providers/dashboard_provider.dart';
import './providers/vendor_provider.dart';
import './tabs/appeal_tab.dart';
import './tabs/config_tab.dart';
import './tabs/dashboard_tab.dart';
import './tabs/vendors_tab.dart';

/// Root scaffold for the MarketPlace section.
///
/// Wraps all four tabs in their own providers so each tab manages its own
/// state independently. Uses [IndexedStack] to preserve scroll/state when
/// switching tabs.
///
/// Tabs:
///   0 → Dashboard  (overview stats)
///   1 → Vendors    (pending approvals)
///   2 → Appeals    (disputed orders)
///   3 → Config     (app settings)
class MarketPlaceShell extends StatefulWidget {
  const MarketPlaceShell({super.key});

  @override
  State<MarketPlaceShell> createState() => _MarketPlaceShellState();
}

class _MarketPlaceShellState extends State<MarketPlaceShell> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabItem(icon: Icons.storefront_rounded, label: 'Overview'),
    _TabItem(icon: Icons.store_rounded, label: 'Vendors'),
    _TabItem(icon: Icons.gavel_rounded, label: 'Appeals'),
    _TabItem(icon: Icons.tune_rounded, label: 'Config'),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Each provider is scoped to this shell — they don't pollute
      // the top-level provider tree from app.dart.
      providers: [
        ChangeNotifierProvider(
          create: (_) => MarketDashboardProvider(MarketDashboardService()),
        ),
        ChangeNotifierProvider(
          create: (_) => VendorProvider(VendorService()),
        ),
        ChangeNotifierProvider(
          create: (_) => AppealProvider(AppealService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ConfigProvider(ConfigService()),
        ),
      ],
      child: Builder(
        builder: (ctx) => Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              DashboardTab(),
              VendorsTab(),
              AppealTab(),
              ConfigTab(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: AppTheme.divider, width: 1)),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              items: _tabs
                  .asMap()
                  .entries
                  .map((e) => BottomNavigationBarItem(
                icon: _BadgedIcon(
                  icon: e.value.icon,
                  tabIndex: e.key,
                  currentIndex: _currentIndex,
                  // Pass providers here for badge counts
                  vendorProvider: ctx.watch<VendorProvider>(),
                  appealProvider: ctx.watch<AppealProvider>(),
                ),
                label: e.value.label,
              ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Badged icon — shows red dot on Vendors/Appeals when count > 0 ──────────────

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({
    required this.icon,
    required this.tabIndex,
    required this.currentIndex,
    required this.vendorProvider,
    required this.appealProvider,
  });

  final IconData icon;
  final int tabIndex;
  final int currentIndex;
  final VendorProvider vendorProvider;
  final AppealProvider appealProvider;

  int get _count {
    if (tabIndex == 1) return vendorProvider.count;
    if (tabIndex == 2) return appealProvider.count;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final count = _count;
    final isActive = tabIndex == currentIndex;

    return Badge(
      isLabelVisible: count > 0 && !isActive,
      label: Text(count.toString()),
      backgroundColor: AppTheme.danger,
      child: Icon(icon),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}