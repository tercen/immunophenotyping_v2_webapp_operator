import 'package:flutter/material.dart';
import '../../../screens/settings_screen.dart';
import '../../../webapp_data.dart';

/// Wraps the existing SettingsScreen for embedding in AppShell MainContent.
///
/// Phase 4: Embeds the full legacy screen as-is. The screen internally uses
/// ScreenBase mixin with folder selector, marker multi-check grid,
/// parameter inputs, dynamic settings, and run analysis button.
class ConfigContent extends StatelessWidget {
  final WebAppData appData;

  const ConfigContent({super.key, required this.appData});

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(appData);
  }
}
