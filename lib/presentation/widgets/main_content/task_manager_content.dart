import 'package:flutter/material.dart';
import '../../../screens/task_manager_screen.dart';
import '../../../webapp_data.dart';

/// Wraps the existing ImmunoTaskManagerScreen for embedding in AppShell MainContent.
///
/// Phase 1: Embeds the full legacy screen as-is. The screen internally uses
/// ScreenBase mixin with ActionBarComponent, ActionTableComponent (workflows),
/// and WorkflowTaskComponent (running tasks).
class TaskManagerContent extends StatelessWidget {
  final WebAppData appData;

  const TaskManagerContent({super.key, required this.appData});

  @override
  Widget build(BuildContext context) {
    return ImmunoTaskManagerScreen(appData);
  }
}
