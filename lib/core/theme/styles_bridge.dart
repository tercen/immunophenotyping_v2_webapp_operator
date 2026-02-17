import 'package:flutter/material.dart';
import 'package:webapp_ui_commons/styles/style_base.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'app_colors.dart';
import 'app_colors_dark.dart';

/// Light theme style that overrides DefaultStyle entries with Tercen design tokens.
class TercenLightStyle extends StyleBase {
  @override
  void init() {
    // Colors
    styleMap["black"] = AppColors.textPrimary;
    styleMap["lightBlack"] = AppColors.neutral400;
    styleMap["gray"] = AppColors.neutral300;
    styleMap["darkGray"] = AppColors.neutral500;
    styleMap["white"] = AppColors.neutral50;
    styleMap["clear"] = AppColors.white;
    styleMap["linkBlue"] = AppColors.link;
    styleMap["red"] = AppColors.error;
    styleMap["buttonBgLight"] = AppColors.primary;
    styleMap["selectedBg"] = AppColors.primarySurface;
    styleMap["selectedMenuBg"] = AppColors.primary;
    styleMap["selectedMenuFg"] = AppColors.white;
    styleMap["hoverBg"] = AppColors.primarySurface;
    styleMap["tooltipBg"] = AppColors.neutral800;
    styleMap["headerRow"] = AppColors.primaryBg;
    styleMap["evenRow"] = AppColors.white;
    styleMap["oddRow"] = AppColors.neutral50;

    // Spacing
    styleMap["paddingSmall"] = 4.0;
    styleMap["paddingMedium"] = 16.0;
    styleMap["paddingLarge"] = 24.0;

    // Border
    styleMap["borderRounding"] = BorderRadius.circular(8.0);

    // Text styles
    styleMap["textH1"] = const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
    styleMap["textH2"] = const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
    styleMap["menuText"] = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
    styleMap["menuTextSelected"] = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.white,
    );
    styleMap["menuTextDisabled"] = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textDisabled,
    );
    styleMap["text"] = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    );
    styleMap["textIt"] = const TextStyle(
      fontSize: 13,
      fontStyle: FontStyle.italic,
      color: AppColors.textPrimary,
    );
    styleMap["textGray"] = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
    );
    styleMap["textTooltip"] = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.white,
    );
    styleMap["textFile"] = const TextStyle(
      fontSize: 12,
      fontFamily: "RobotoMono",
      color: AppColors.textPrimary,
    );
    styleMap["textBold"] = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );
    styleMap["textButton"] = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.white,
    );
    styleMap["textHref"] = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.link,
      decoration: TextDecoration.underline,
    );
    styleMap["textBlocked"] = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.white,
    );

    // Decorations
    styleMap["tooltipDecoration"] = BoxDecoration(
      color: AppColors.neutral800,
      borderRadius: BorderRadius.circular(8.0),
    );
    styleMap["buttonEnabled"] = ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
    );
    styleMap["buttonDisabled"] = ElevatedButton.styleFrom(
      backgroundColor: AppColors.textDisabled,
      foregroundColor: AppColors.white,
    );
  }
}

/// Dark theme style that overrides DefaultStyle entries with Tercen dark tokens.
class TercenDarkStyle extends StyleBase {
  @override
  void init() {
    // Colors
    styleMap["black"] = AppColorsDark.textPrimary;
    styleMap["lightBlack"] = AppColorsDark.neutral400;
    styleMap["gray"] = AppColorsDark.neutral700;
    styleMap["darkGray"] = AppColorsDark.textMuted;
    styleMap["white"] = AppColorsDark.neutral50;
    styleMap["clear"] = AppColorsDark.surface;
    styleMap["linkBlue"] = AppColorsDark.link;
    styleMap["red"] = AppColorsDark.error;
    styleMap["buttonBgLight"] = AppColorsDark.primary;
    styleMap["selectedBg"] = AppColorsDark.primarySurface;
    styleMap["selectedMenuBg"] = AppColorsDark.primary;
    styleMap["selectedMenuFg"] = const Color(0xFFFFFFFF);
    styleMap["hoverBg"] = AppColorsDark.primarySurface;
    styleMap["tooltipBg"] = AppColorsDark.surfaceElevated;
    styleMap["headerRow"] = AppColorsDark.primaryBg;
    styleMap["evenRow"] = AppColorsDark.surface;
    styleMap["oddRow"] = AppColorsDark.surfaceElevated;

    // Spacing
    styleMap["paddingSmall"] = 4.0;
    styleMap["paddingMedium"] = 16.0;
    styleMap["paddingLarge"] = 24.0;

    // Border
    styleMap["borderRounding"] = BorderRadius.circular(8.0);

    // Text styles
    styleMap["textH1"] = const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColorsDark.textPrimary,
    );
    styleMap["textH2"] = const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColorsDark.textPrimary,
    );
    styleMap["menuText"] = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColorsDark.textPrimary,
    );
    styleMap["menuTextSelected"] = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xFFFFFFFF),
    );
    styleMap["menuTextDisabled"] = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColorsDark.textDisabled,
    );
    styleMap["text"] = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColorsDark.textPrimary,
    );
    styleMap["textIt"] = const TextStyle(
      fontSize: 13,
      fontStyle: FontStyle.italic,
      color: AppColorsDark.textPrimary,
    );
    styleMap["textGray"] = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColorsDark.textMuted,
    );
    styleMap["textTooltip"] = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: Color(0xFFFFFFFF),
    );
    styleMap["textFile"] = const TextStyle(
      fontSize: 12,
      fontFamily: "RobotoMono",
      color: AppColorsDark.textPrimary,
    );
    styleMap["textBold"] = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: AppColorsDark.textPrimary,
    );
    styleMap["textButton"] = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFFFFFFFF),
    );
    styleMap["textHref"] = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColorsDark.link,
      decoration: TextDecoration.underline,
    );
    styleMap["textBlocked"] = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: Color(0xFFFFFFFF),
    );

    // Decorations
    styleMap["tooltipDecoration"] = BoxDecoration(
      color: AppColorsDark.surfaceElevated,
      borderRadius: BorderRadius.circular(8.0),
    );
    styleMap["buttonEnabled"] = ElevatedButton.styleFrom(
      backgroundColor: AppColorsDark.primary,
      foregroundColor: const Color(0xFFFFFFFF),
    );
    styleMap["buttonDisabled"] = ElevatedButton.styleFrom(
      backgroundColor: AppColorsDark.textDisabled,
      foregroundColor: const Color(0xFFFFFFFF),
    );
  }
}

/// Syncs the legacy Styles() singleton with the current Tercen theme.
/// Call this whenever the theme changes.
class StylesBridge {
  static void syncStyles(bool isDark) {
    if (isDark) {
      Styles().init([TercenDarkStyle()]);
    } else {
      Styles().init([TercenLightStyle()]);
    }
  }
}
