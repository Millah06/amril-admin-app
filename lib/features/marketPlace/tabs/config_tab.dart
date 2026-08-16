import 'package:flutter/material.dart';

import '../screens/config/config_view_screen.dart';

/// Config tab — now a read-only VIEW that opens a dedicated EDIT page (§3).
/// The old inline editable form moved to [ConfigEditScreen]. This wrapper keeps
/// the shell's tab wiring (`ConfigTab`) stable.
class ConfigTab extends StatelessWidget {
  const ConfigTab({super.key});

  @override
  Widget build(BuildContext context) => const ConfigViewScreen();
}
