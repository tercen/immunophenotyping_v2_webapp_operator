import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/theme_provider.dart';

/// Left panel section for Configuration controls.
///
/// Phase 4: Minimal info display. The folder selector, marker grid,
/// parameter inputs, and run button remain inside the embedded
/// SettingsScreen for now.
class ConfigControlsSection extends StatelessWidget {
  const ConfigControlsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textColor =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Text(
      'Configure markers, parameters, and run the analysis workflow.',
      style: AppTextStyles.body.copyWith(color: textColor),
    );
  }
}
