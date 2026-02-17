import 'package:flutter/foundation.dart';

/// Workflow step definitions for the immunophenotyping app.
enum WorkflowStep {
  upload(0, 'Upload Data', 'Upload'),
  configuration(1, 'Configuration', 'Config'),
  report(2, 'Report', 'Report'),
  taskManager(3, 'Task Manager', 'Tasks');

  const WorkflowStep(this.stepIndex, this.label, this.shortLabel);
  final int stepIndex;
  final String label;
  final String shortLabel;
}

/// Manages navigation between workflow steps in the AppShell.
/// Replaces the old `app.navMenu.selectScreen()` pattern.
class NavigationProvider extends ChangeNotifier {
  WorkflowStep _activeStep = WorkflowStep.upload;

  /// Tracks which steps have been completed or are accessible.
  final Set<WorkflowStep> _enabledSteps = {
    WorkflowStep.upload,
    WorkflowStep.taskManager,
  };

  WorkflowStep get activeStep => _activeStep;
  Set<WorkflowStep> get enabledSteps => Set.unmodifiable(_enabledSteps);

  bool isStepEnabled(WorkflowStep step) => _enabledSteps.contains(step);

  /// Navigate to a step. Only allowed if the step is enabled.
  void selectStep(WorkflowStep step) {
    if (!_enabledSteps.contains(step)) return;
    if (_activeStep == step) return;
    _activeStep = step;
    notifyListeners();
  }

  /// Enable a step (e.g., after upload completes, enable Configuration).
  void enableStep(WorkflowStep step) {
    if (_enabledSteps.add(step)) {
      notifyListeners();
    }
  }

  /// Enable multiple steps at once.
  void enableSteps(Iterable<WorkflowStep> steps) {
    bool changed = false;
    for (final step in steps) {
      if (_enabledSteps.add(step)) changed = true;
    }
    if (changed) notifyListeners();
  }

  /// Enable all steps (e.g., when loading an existing project with data).
  void enableAllSteps() {
    enableSteps(WorkflowStep.values);
  }
}
