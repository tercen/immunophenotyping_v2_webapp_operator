import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

import '../../core/theme/styles_bridge.dart';
import '../../webapp.dart';
import '../../webapp_data.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_shell.dart';
import '../widgets/left_panel/config_controls_section.dart';
import '../widgets/left_panel/left_panel.dart';
import '../widgets/left_panel/report_controls_section.dart';
import '../widgets/left_panel/task_controls_section.dart';
import '../widgets/left_panel/upload_controls_section.dart';
import '../widgets/left_panel/workflow_stepper_section.dart';
import '../widgets/main_content/config_content.dart';
import '../widgets/main_content/report_content.dart';
import '../widgets/main_content/task_manager_content.dart';
import '../widgets/main_content/upload_content.dart';

/// Home screen: initializes WebApp/WebAppData, then assembles AppShell
/// with dynamic sections and content based on active workflow step.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with ProgressDialog {
  bool _initialized = false;
  String? _error;
  late final WebApp app;
  late final WebAppData appData;

  @override
  void initState() {
    super.initState();

    app = WebApp();
    appData = WebAppData(app);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Capture provider references before async gaps
      final navProvider = context.read<NavigationProvider>();
      final isDark = context.read<ThemeProvider>().isDarkMode;

      try {
        // Sync Styles() bridge with current theme
        StylesBridge.syncStyles(isDark);

        openDialog(context);
        log("Initializing User Session", dialogTitle: "WebApp");

        await app.init();
        await PackageInfo.fromPlatform();

        log("Initializing File Structure", dialogTitle: "WebApp");

        await appData.init(
          app.projectId,
          app.projectName,
          app.username,
          reposJsonPath: "assets/repos.json",
          settingFilterFile: "assets/settings_screen_filter.json",
          stepMapperJsonFile: "assets/workflow_steps.json",
        );

        app.isInitialized = true;

        // Enable all steps for now (will be refined per-phase)
        navProvider.enableAllSteps();

        closeLog();
        if (!mounted) return;
        setState(() => _initialized = true);
      } catch (e) {
        closeLog();
        if (!mounted) return;
        setState(() => _error = e.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorView();
    }

    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Listen to theme changes to keep Styles() bridge in sync
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    StylesBridge.syncStyles(isDark);

    final activeStep = context.watch<NavigationProvider>().activeStep;

    return AppShell(
      appTitle: 'Immunophenotyping',
      appIcon: Icons.biotech,
      sections: _buildSections(activeStep),
      content: _buildContent(activeStep),
    );
  }

  /// Build left panel sections based on active workflow step.
  List<PanelSection> _buildSections(WorkflowStep activeStep) {
    // Workflow stepper is always present
    final sections = <PanelSection>[
      const PanelSection(
        icon: Icons.linear_scale,
        label: 'Workflow',
        content: WorkflowStepperSection(),
      ),
    ];

    // Add step-specific sections
    switch (activeStep) {
      case WorkflowStep.upload:
        sections.add(const PanelSection(
          icon: Icons.upload_file,
          label: 'Upload',
          content: UploadControlsSection(),
        ));
        break;
      case WorkflowStep.configuration:
        sections.add(const PanelSection(
          icon: Icons.tune,
          label: 'Configuration',
          content: ConfigControlsSection(),
        ));
        break;
      case WorkflowStep.report:
        sections.add(const PanelSection(
          icon: Icons.assessment,
          label: 'Reports',
          content: ReportControlsSection(),
        ));
        break;
      case WorkflowStep.taskManager:
        sections.add(const PanelSection(
          icon: Icons.list_alt,
          label: 'Tasks',
          content: TaskControlsSection(),
        ));
        break;
    }

    return sections;
  }

  /// Build main content based on active workflow step.
  Widget _buildContent(WorkflowStep activeStep) {
    switch (activeStep) {
      case WorkflowStep.upload:
        return UploadContent(appData: appData);
      case WorkflowStep.configuration:
        return ConfigContent(appData: appData);
      case WorkflowStep.report:
        return ReportContent(appData: appData);
      case WorkflowStep.taskManager:
        return TaskManagerContent(appData: appData);
    }
  }

  Widget _buildErrorView() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Initialization Error',
                style: Styles()["textH2"] ?? const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            SelectableText(_error ?? 'Unknown error',
                style: Styles()["text"] ?? const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
