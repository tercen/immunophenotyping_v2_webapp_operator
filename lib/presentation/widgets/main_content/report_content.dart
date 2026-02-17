import 'package:flutter/material.dart';
import '../../../screens/report_screen.dart';
import '../../../webapp_data.dart';

/// Wraps the existing ReportScreen for embedding in AppShell MainContent.
///
/// Phase 2: Embeds the full legacy screen as-is. The screen internally uses
/// ScreenBase mixin with SingleSelectTableComponent (workflow selector)
/// and ImmunoImageListComponent (image gallery + PDF/PPT download).
class ReportContent extends StatelessWidget {
  final WebAppData appData;

  const ReportContent({super.key, required this.appData});

  @override
  Widget build(BuildContext context) {
    return ReportScreen(appData);
  }
}
