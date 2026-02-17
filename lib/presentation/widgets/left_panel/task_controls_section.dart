import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/theme_provider.dart';

/// Left panel section for Task Manager controls.
///
/// Phase 1: Minimal info display. The actual refresh/filter controls
/// remain inside the embedded ImmunoTaskManagerScreen for now.
class TaskControlsSection extends StatelessWidget {
  const TaskControlsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Text(
      'View running tasks and completed workflows.',
      style: AppTextStyles.body.copyWith(color: textColor),
    );
  }
}
