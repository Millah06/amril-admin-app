import 'package:admin_panel/features/marketPlace/providers/appeal_provider.dart';
import 'package:admin_panel/features/marketPlace/providers/config_provider.dart';
import 'package:admin_panel/features/marketPlace/providers/dashboard_provider.dart';
import 'package:admin_panel/features/marketPlace/providers/hardware_provider.dart';
import 'package:provider/provider.dart';
import '../../../features/marketPlace/providers/vendor_provider.dart';
import "package:flutter/material.dart";

Future<T?> marketPush<T>(BuildContext context, Widget page) {
  // Capture all providers from the current context before pushing
  final market          = context.read<MarketDashboardProvider>();
  final vendor    = context.read<VendorProvider>();
  final appeal  = context.read<AppealProvider>();
  final config      = context.read<ConfigProvider>();
  final hardware    = context.read<HardwareProvider>();


  return Navigator.push<T>(
    context,
    MaterialPageRoute(
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: market),
          ChangeNotifierProvider.value(value: vendor),
          ChangeNotifierProvider.value(value: appeal),
          ChangeNotifierProvider.value(value: config),
          ChangeNotifierProvider.value(value: hardware),

        ],
        child: page,
      ),
    ),
  );
}