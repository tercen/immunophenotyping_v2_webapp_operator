import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/theme_provider.dart';

/// Left panel section for Upload controls.
///
/// Phase 3: Minimal info display. The project name, team selector,
/// file upload zones, and upload button remain inside the embedded
/// UploadScreen for now.
class UploadControlsSection extends StatelessWidget {
  const UploadControlsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textColor =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Text(
      'Upload FCS and annotation files to create a new project.',
      style: AppTextStyles.body.copyWith(color: textColor),
    );
  }
}
