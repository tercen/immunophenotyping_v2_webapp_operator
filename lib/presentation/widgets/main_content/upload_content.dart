import 'package:flutter/material.dart';
import '../../../screens/upload_screen.dart';
import '../../../webapp_data.dart';

/// Wraps the existing UploadScreen for embedding in AppShell MainContent.
///
/// Phase 3: Embeds the full legacy screen as-is. The screen internally uses
/// ScreenBase mixin with InputTextComponent (project name),
/// SelectFromListComponent (team), UploadFileTeamComponent (FCS),
/// UploadTableTeamComponent (annotation), and ButtonActionComponent (upload).
class UploadContent extends StatelessWidget {
  final WebAppData appData;

  const UploadContent({super.key, required this.appData});

  @override
  Widget build(BuildContext context) {
    return UploadScreen(appData);
  }
}
