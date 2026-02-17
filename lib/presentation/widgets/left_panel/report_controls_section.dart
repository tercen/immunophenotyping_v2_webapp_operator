import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/theme_provider.dart';

/// Left panel section for Report controls.
///
/// Phase 2: Minimal info display. The workflow selector and image gallery
/// remain inside the embedded ReportScreen for now.
class ReportControlsSection extends StatelessWidget {
  const ReportControlsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textColor =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Text(
      'Select a workflow to view images and download reports.',
      style: AppTextStyles.body.copyWith(color: textColor),
    );
  }
}
