import 'package:flutter/material.dart';

import 'app_tokens.dart';

export 'app_tokens.dart';

abstract final class AppColors {
  static const ink = Color(0xFF28174E);
  static const deepPurple = Color(0xFF462A7E);
  static const purple = Color(0xFF7D6AC6);
  // Variante quase idêntica ao roxo de marca, escurecida apenas o suficiente
  // para receber texto branco pequeno com contraste WCAG AA.
  static const purpleAccessible = Color(0xFF7A67C2);
  static const lavender = Color(0xFFDBCFFF);
  static const porcelain = Color(0xFFFAF9F6);
  static const white = Color(0xFFFFFFFF);
  static const text = Color(0xFF241B35);
  static const muted = Color(0xFF756D82);
  static const outline = Color(0xFFE5DFEB);
  static const outlineStrong = Color(0xFF91879E);
  static const success = Color(0xFF3D7A55);
  static const danger = Color(0xFFB94352);

  static const successContainer = Color(0xFFE7F3EA);
  static const onSuccessContainer = Color(0xFF245035);
  static const warning = Color(0xFF8A5B16);
  static const warningContainer = Color(0xFFFFF1D6);
  static const onWarningContainer = Color(0xFF5D3A0B);
  static const info = Color(0xFF466BC7);
  static const infoContainer = Color(0xFFE5EDFF);
  static const onInfoContainer = Color(0xFF24437E);
  static const dangerContainer = Color(0xFFFBEAEC);
  static const onDangerContainer = Color(0xFF6F2330);

  static const darkBackground = Color(0xFF17121F);
  static const darkSurface = Color(0xFF241C31);
  static const darkSurfaceContainer = Color(0xFF2C2339);
  static const darkSurfaceContainerHigh = Color(0xFF352A43);
  static const darkOutline = Color(0xFF796B87);
  static const darkOutlineVariant = Color(0xFF443653);
  static const darkText = Color(0xFFF5EFFA);
  static const darkMuted = Color(0xFFC5B9D0);
  static const darkError = Color(0xFFFFB2BA);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purpleAccessible, deepPurple, ink],
  );
}

abstract final class AppTheme {
  static const _lightSemanticColors = AppSemanticColors(
    success: AppColors.success,
    onSuccess: AppColors.white,
    successContainer: AppColors.successContainer,
    onSuccessContainer: AppColors.onSuccessContainer,
    warning: AppColors.warning,
    onWarning: AppColors.white,
    warningContainer: AppColors.warningContainer,
    onWarningContainer: AppColors.onWarningContainer,
    info: AppColors.info,
    onInfo: AppColors.white,
    infoContainer: AppColors.infoContainer,
    onInfoContainer: AppColors.onInfoContainer,
  );

  static const _darkSemanticColors = AppSemanticColors(
    success: Color(0xFF8FD1A7),
    onSuccess: Color(0xFF153824),
    successContainer: Color(0xFF244C34),
    onSuccessContainer: Color(0xFFD9F3E2),
    warning: Color(0xFFF1C36E),
    onWarning: Color(0xFF4A3007),
    warningContainer: Color(0xFF50390F),
    onWarningContainer: Color(0xFFFFE8B3),
    info: Color(0xFFAFC7FF),
    onInfo: Color(0xFF19386E),
    infoContainer: Color(0xFF294A80),
    onInfoContainer: Color(0xFFE2EAFF),
  );

  static final ColorScheme _lightColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.light,
        primary: AppColors.deepPurple,
        secondary: AppColors.purpleAccessible,
        surface: AppColors.white,
        error: AppColors.danger,
      ).copyWith(
        onPrimary: AppColors.white,
        primaryContainer: AppColors.lavender,
        onPrimaryContainer: AppColors.ink,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.lavender,
        onSecondaryContainer: AppColors.ink,
        onSurface: AppColors.text,
        onSurfaceVariant: AppColors.muted,
        surfaceContainerLowest: AppColors.white,
        surfaceContainerLow: AppColors.porcelain,
        surfaceContainer: const Color(0xFFF5F1F7),
        surfaceContainerHigh: const Color(0xFFF0EBF3),
        surfaceContainerHighest: const Color(0xFFEAE4EF),
        outline: AppColors.outlineStrong,
        outlineVariant: AppColors.outline,
        onError: AppColors.white,
        errorContainer: AppColors.dangerContainer,
        onErrorContainer: AppColors.onDangerContainer,
        shadow: AppColors.ink,
        scrim: AppColors.ink,
      );

  static final ColorScheme _darkColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.dark,
        primary: AppColors.lavender,
        secondary: const Color(0xFFC8B8F4),
        surface: AppColors.darkSurface,
        error: AppColors.darkError,
      ).copyWith(
        onPrimary: AppColors.ink,
        primaryContainer: AppColors.deepPurple,
        onPrimaryContainer: AppColors.darkText,
        onSecondary: AppColors.ink,
        secondaryContainer: const Color(0xFF3E2D73),
        onSecondaryContainer: AppColors.darkText,
        onSurface: AppColors.darkText,
        onSurfaceVariant: AppColors.darkMuted,
        surfaceContainerLowest: AppColors.darkBackground,
        surfaceContainerLow: AppColors.darkSurface,
        surfaceContainer: AppColors.darkSurfaceContainer,
        surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
        surfaceContainerHighest: const Color(0xFF40334F),
        outline: AppColors.darkOutline,
        outlineVariant: AppColors.darkOutlineVariant,
        onError: const Color(0xFF4B111A),
        errorContainer: const Color(0xFF702734),
        onErrorContainer: const Color(0xFFFFD9DD),
        shadow: Colors.black,
        scrim: Colors.black,
      );

  /// A tipografia usa deliberadamente a família padrão de cada plataforma.
  /// Nunito não é declarada porque não há arquivos dessa fonte no projeto.
  static TextTheme _textTheme(ColorScheme colors) {
    return TextTheme(
      displayLarge: TextStyle(
        color: colors.onSurface,
        fontSize: 48,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      displayMedium: TextStyle(
        color: colors.onSurface,
        fontSize: 42,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      displaySmall: TextStyle(
        color: colors.onSurface,
        fontSize: 38,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineLarge: TextStyle(
        color: colors.onSurface,
        fontSize: 32,
        height: 1.18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.35,
      ),
      headlineMedium: TextStyle(
        color: colors.onSurface,
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
      headlineSmall: TextStyle(
        color: colors.onSurface,
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: colors.onSurface,
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: colors.onSurface,
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: TextStyle(
        color: colors.onSurface,
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(color: colors.onSurface, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(
        color: colors.onSurfaceVariant,
        fontSize: 14,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: colors.onSurfaceVariant,
        fontSize: 12,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        color: colors.onSurface,
        fontSize: 15,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: TextStyle(
        color: colors.onSurfaceVariant,
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: TextStyle(
        color: colors.onSurfaceVariant,
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static ThemeData get light => _buildTheme(
    colorScheme: _lightColorScheme,
    scaffoldBackgroundColor: AppColors.porcelain,
    semanticColors: _lightSemanticColors,
  );

  static ThemeData get dark => _buildTheme(
    colorScheme: _darkColorScheme,
    scaffoldBackgroundColor: AppColors.darkBackground,
    semanticColors: _darkSemanticColors,
  );

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required AppSemanticColors semanticColors,
  }) {
    final textTheme = _textTheme(colorScheme);
    final isDark = colorScheme.brightness == Brightness.dark;
    final inputFill = isDark ? AppColors.darkSurfaceContainer : AppColors.white;
    final cardBorder = colorScheme.outlineVariant;
    final buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.medium);
    final inputShape = OutlineInputBorder(
      borderRadius: AppRadius.medium,
      borderSide: BorderSide(color: colorScheme.outline),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[semanticColors],
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      focusColor: colorScheme.primary.withValues(alpha: .18),
      hoverColor: colorScheme.primary.withValues(alpha: .08),
      highlightColor: colorScheme.primary.withValues(alpha: .1),
      disabledColor: colorScheme.onSurface.withValues(alpha: .38),
      appBarTheme: AppBarTheme(
        elevation: AppElevation.none,
        scrolledUnderElevation: AppElevation.none,
        centerTitle: false,
        backgroundColor: scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.none,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(color: cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        constraints: const BoxConstraints(minHeight: AppSize.controlHeight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium,
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
        prefixIconConstraints: const BoxConstraints(
          minWidth: AppSize.minimumTapTarget,
          minHeight: AppSize.minimumTapTarget,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: AppSize.minimumTapTarget,
          minHeight: AppSize.minimumTapTarget,
        ),
        border: inputShape,
        enabledBorder: inputShape,
        disabledBorder: inputShape.copyWith(
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: inputShape.copyWith(
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            AppSize.minimumTapTarget,
            AppSize.controlHeight,
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: .12),
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: .38),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppSize.minimumTapTarget,
            AppSize.controlHeight,
          ),
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: .38),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          side: BorderSide(color: colorScheme.primary),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            AppSize.minimumTapTarget,
            AppSize.controlHeight,
          ),
          elevation: AppElevation.floating,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.primary,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppSize.minimumTapTarget,
            AppSize.minimumTapTarget,
          ),
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSize.minimumTapTarget),
          foregroundColor: colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: AppElevation.floating,
        focusElevation: AppElevation.floating,
        hoverElevation: AppElevation.floating,
        highlightElevation: AppElevation.modal,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.onSurface.withValues(alpha: .08),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: const StadiumBorder(),
      ),
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
      ),
      radioTheme: const RadioThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      switchTheme: SwitchThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: .38);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: .12);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      dialogTheme: DialogThemeData(
        elevation: AppElevation.modal,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: AppElevation.modal,
        modalElevation: AppElevation.modal,
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
        ),
        actionTextColor: AppColors.lavender,
        behavior: SnackBarBehavior.floating,
        elevation: AppElevation.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
      ),
      tooltipTheme: TooltipThemeData(
        constraints: const BoxConstraints(
          minHeight: AppSize.minimumTapTarget,
          maxWidth: 280,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: AppRadius.small,
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: AppSpacing.sm,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: AppRadius.small),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant;
          return textTheme.labelLarge?.copyWith(color: color);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        indicatorColor: colorScheme.primary,
        dividerColor: colorScheme.outlineVariant,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withValues(alpha: .24),
        selectionHandleColor: colorScheme.primary,
      ),
    );
  }
}

abstract final class AppThemeController {
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDark => mode.value == ThemeMode.dark;

  static void setDarkMode(bool enabled) {
    mode.value = enabled ? ThemeMode.dark : ThemeMode.light;
  }
}
