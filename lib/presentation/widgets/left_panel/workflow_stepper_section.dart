import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/theme_provider.dart';

/// Workflow stepper displayed in the LeftPanel WORKFLOW section.
/// Shows 4 steps with active/enabled/disabled states.
class WorkflowStepperSection extends StatelessWidget {
  const WorkflowStepperSection({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Column(
      children: WorkflowStep.values.map((step) {
        final isActive = nav.activeStep == step;
        final isEnabled = nav.isStepEnabled(step);
        return _StepTile(
          step: step,
          isActive: isActive,
          isEnabled: isEnabled,
          isDark: isDark,
          onTap: isEnabled
              ? () => context.read<NavigationProvider>().selectStep(step)
              : null,
        );
      }).toList(),
    );
  }
}

class _StepTile extends StatelessWidget {
  final WorkflowStep step;
  final bool isActive;
  final bool isEnabled;
  final bool isDark;
  final VoidCallback? onTap;

  const _StepTile({
    required this.step,
    required this.isActive,
    required this.isEnabled,
    required this.isDark,
    this.onTap,
  });

  IconData _iconForStep(WorkflowStep step) {
    switch (step) {
      case WorkflowStep.upload:
        return Icons.upload_file;
      case WorkflowStep.configuration:
        return Icons.tune;
      case WorkflowStep.report:
        return Icons.assessment;
      case WorkflowStep.taskManager:
        return Icons.list_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? AppColorsDark.primarySurface : AppColors.primarySurface;
    final activeText = isDark ? AppColorsDark.primary : AppColors.primary;
    final enabledText = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final disabledText = isDark ? AppColorsDark.textDisabled : AppColors.textDisabled;

    final bgColor = isActive ? activeBg : Colors.transparent;
    final textColor = isActive ? activeText : (isEnabled ? enabledText : disabledText);
    final iconColor = textColor;

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs + 2,
          ),
          child: Row(
            children: [
              // Step number circle
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? activeText
                      : (isEnabled
                          ? (isDark ? AppColorsDark.border : AppColors.border)
                          : Colors.transparent),
                  border: Border.all(
                    color: isActive
                        ? activeText
                        : (isEnabled
                            ? (isDark ? AppColorsDark.border : AppColors.border)
                            : disabledText),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${step.stepIndex + 1}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isActive
                          ? Colors.white
                          : (isEnabled ? enabledText : disabledText),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Step icon
              Icon(_iconForStep(step), size: 16, color: iconColor),
              const SizedBox(width: AppSpacing.xs),
              // Step label
              Expanded(
                child: Text(
                  step.label,
                  style: AppTextStyles.label.copyWith(
                    color: textColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
