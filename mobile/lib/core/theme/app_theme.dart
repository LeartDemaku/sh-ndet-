import 'package:flutter/material.dart';

/// Ngjyrat bazë të markës (të pandryshueshme në të dyja pamjet).
class ShendetColors {
  static const primary = Color(0xFF0F766E);
  static const primaryDark = Color(0xFF115E59);
  static const primaryLight = Color(0xFF14B8A6);

  static const emergency = Color(0xFFB91C1C);
  static const urgent = Color(0xFFC2410C);
  static const soon = Color(0xFF1D4ED8);
  static const selfCare = Color(0xFF15803D);

  // Ngjyra theksuese për ikona dhe karta (jo për tekst mbi to).
  static const amber = Color(0xFFF59E0B);
  static const sky = Color(0xFF0EA5E9);
  static const violet = Color(0xFF8B5CF6);
  static const rose = Color(0xFFE11D48);

  /// Mbi të kuqen e emergjencës teksti mbetet i bardhë në çdo pamje.
  static const onEmergency = Color(0xFFFFFFFF);
}

/// Grida 4pt.
class Gap {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Madhësia minimale e targetit prekës (lista e kontrollit e aksesueshmërisë).
const double kTouchTarget = 48;

/// Grada qendrore e markës (e njëjta në light dhe dark).
class ShendetGradients {
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B3B36), Color(0xFF0F766E), Color(0xFF14B8A6)],
  );

  static const primary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
  );
}

/// Paleta semantike: çdo ekran lexon tokenat nga këtu, që light dhe dark
/// të ndryshojnë vetëm në këtë skedar.
@immutable
class ShendetPalette extends ThemeExtension<ShendetPalette> {
  const ShendetPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceSunken,
    required this.ink,
    required this.muted,
    required this.line,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.onPrimary,
    required this.mint,
    required this.emergency,
    required this.urgent,
    required this.soon,
    required this.selfCare,
    required this.amber,
    required this.sky,
    required this.violet,
    required this.rose,
    required this.emergencySurface,
    required this.emergencyBorder,
    required this.warningSurface,
    required this.warningBorder,
    required this.infoSurface,
    required this.infoBorder,
    required this.successSurface,
    required this.successBorder,
    required this.softGradient,
    required this.shadow,
    required this.inverseSurface,
    required this.onInverse,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceSunken;
  final Color ink;
  final Color muted;
  final Color line;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color onPrimary;
  final Color mint;
  final Color emergency;
  final Color urgent;
  final Color soon;
  final Color selfCare;
  final Color amber;
  final Color sky;
  final Color violet;
  final Color rose;
  final Color emergencySurface;
  final Color emergencyBorder;
  final Color warningSurface;
  final Color warningBorder;
  final Color infoSurface;
  final Color infoBorder;
  final Color successSurface;
  final Color successBorder;
  final LinearGradient softGradient;
  final Color shadow;
  final Color inverseSurface;
  final Color onInverse;

  /// Pamja e ndritshme (e njëjta pamje si deri tani).
  static const light = ShendetPalette(
    background: Color(0xFFF6FAF9),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0FDFA),
    surfaceSunken: Color(0xFFF1F5F9),
    ink: Color(0xFF0F172A),
    muted: Color(0xFF64748B),
    line: Color(0xFFE2E8F0),
    primary: Color(0xFF0F766E),
    primaryDark: Color(0xFF115E59),
    primaryLight: Color(0xFF14B8A6),
    onPrimary: Color(0xFFFFFFFF),
    mint: Color(0xFFCCFBF1),
    emergency: Color(0xFFB91C1C),
    urgent: Color(0xFFC2410C),
    soon: Color(0xFF1D4ED8),
    selfCare: Color(0xFF15803D),
    amber: Color(0xFFF59E0B),
    sky: Color(0xFF0EA5E9),
    violet: Color(0xFF8B5CF6),
    rose: Color(0xFFE11D48),
    emergencySurface: Color(0xFFFEF2F2),
    emergencyBorder: Color(0xFFFECACA),
    warningSurface: Color(0xFFFFF7ED),
    warningBorder: Color(0xFFFED7AA),
    infoSurface: Color(0xFFEFF6FF),
    infoBorder: Color(0xFFBFDBFE),
    successSurface: Color(0xFFECFDF5),
    successBorder: Color(0xFFA7F3D0),
    softGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF0FDFA), Color(0xFFF6FAF9)],
    ),
    shadow: Color(0x140F172A),
    inverseSurface: Color(0xFF0F172A),
    onInverse: Color(0xFFFFFFFF),
  );

  /// Pamja e errët: e njëjta strukturë, me kontrast të verifikuar.
  static const dark = ShendetPalette(
    background: Color(0xFF0A1013),
    surface: Color(0xFF121B1F),
    surfaceAlt: Color(0xFF10201E),
    surfaceSunken: Color(0xFF0D1519),
    ink: Color(0xFFE8F2F0),
    muted: Color(0xFF9AAFA9),
    line: Color(0xFF243139),
    primary: Color(0xFF2DD4BF),
    primaryDark: Color(0xFF5EEAD4),
    primaryLight: Color(0xFF14B8A6),
    onPrimary: Color(0xFF03211D),
    mint: Color(0xFF123B35),
    emergency: Color(0xFFF87171),
    urgent: Color(0xFFFB923C),
    soon: Color(0xFF7DB2FF),
    selfCare: Color(0xFF4ADE80),
    amber: Color(0xFFFBBF24),
    sky: Color(0xFF38BDF8),
    violet: Color(0xFFA78BFA),
    rose: Color(0xFFFB7185),
    emergencySurface: Color(0xFF2A1417),
    emergencyBorder: Color(0xFF7F1D1D),
    warningSurface: Color(0xFF2A1C11),
    warningBorder: Color(0xFF9A3412),
    infoSurface: Color(0xFF11202E),
    infoBorder: Color(0xFF1E40AF),
    successSurface: Color(0xFF0E2418),
    successBorder: Color(0xFF166534),
    softGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF10201E), Color(0xFF0A1013)],
    ),
    shadow: Color(0x99000000),
    inverseSurface: Color(0xFFE8F2F0),
    onInverse: Color(0xFF0A1013),
  );

  @override
  ShendetPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceSunken,
    Color? ink,
    Color? muted,
    Color? line,
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? onPrimary,
    Color? mint,
    Color? emergency,
    Color? urgent,
    Color? soon,
    Color? selfCare,
    Color? amber,
    Color? sky,
    Color? violet,
    Color? rose,
    Color? emergencySurface,
    Color? emergencyBorder,
    Color? warningSurface,
    Color? warningBorder,
    Color? infoSurface,
    Color? infoBorder,
    Color? successSurface,
    Color? successBorder,
    LinearGradient? softGradient,
    Color? shadow,
    Color? inverseSurface,
    Color? onInverse,
  }) => ShendetPalette(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
    surfaceSunken: surfaceSunken ?? this.surfaceSunken,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    line: line ?? this.line,
    primary: primary ?? this.primary,
    primaryDark: primaryDark ?? this.primaryDark,
    primaryLight: primaryLight ?? this.primaryLight,
    onPrimary: onPrimary ?? this.onPrimary,
    mint: mint ?? this.mint,
    emergency: emergency ?? this.emergency,
    urgent: urgent ?? this.urgent,
    soon: soon ?? this.soon,
    selfCare: selfCare ?? this.selfCare,
    amber: amber ?? this.amber,
    sky: sky ?? this.sky,
    violet: violet ?? this.violet,
    rose: rose ?? this.rose,
    emergencySurface: emergencySurface ?? this.emergencySurface,
    emergencyBorder: emergencyBorder ?? this.emergencyBorder,
    warningSurface: warningSurface ?? this.warningSurface,
    warningBorder: warningBorder ?? this.warningBorder,
    infoSurface: infoSurface ?? this.infoSurface,
    infoBorder: infoBorder ?? this.infoBorder,
    successSurface: successSurface ?? this.successSurface,
    successBorder: successBorder ?? this.successBorder,
    softGradient: softGradient ?? this.softGradient,
    shadow: shadow ?? this.shadow,
    inverseSurface: inverseSurface ?? this.inverseSurface,
    onInverse: onInverse ?? this.onInverse,
  );

  @override
  ShendetPalette lerp(covariant ShendetPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return ShendetPalette(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      surfaceSunken: mix(surfaceSunken, other.surfaceSunken),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      line: mix(line, other.line),
      primary: mix(primary, other.primary),
      primaryDark: mix(primaryDark, other.primaryDark),
      primaryLight: mix(primaryLight, other.primaryLight),
      onPrimary: mix(onPrimary, other.onPrimary),
      mint: mix(mint, other.mint),
      emergency: mix(emergency, other.emergency),
      urgent: mix(urgent, other.urgent),
      soon: mix(soon, other.soon),
      selfCare: mix(selfCare, other.selfCare),
      amber: mix(amber, other.amber),
      sky: mix(sky, other.sky),
      violet: mix(violet, other.violet),
      rose: mix(rose, other.rose),
      emergencySurface: mix(emergencySurface, other.emergencySurface),
      emergencyBorder: mix(emergencyBorder, other.emergencyBorder),
      warningSurface: mix(warningSurface, other.warningSurface),
      warningBorder: mix(warningBorder, other.warningBorder),
      infoSurface: mix(infoSurface, other.infoSurface),
      infoBorder: mix(infoBorder, other.infoBorder),
      successSurface: mix(successSurface, other.successSurface),
      successBorder: mix(successBorder, other.successBorder),
      softGradient:
          LinearGradient.lerp(softGradient, other.softGradient, t) ??
          softGradient,
      shadow: mix(shadow, other.shadow),
      inverseSurface: mix(inverseSurface, other.inverseSurface),
      onInverse: mix(onInverse, other.onInverse),
    );
  }
}

/// Qasje e shkurtër: `context.palette.ink`, `context.palette.surface`, ...
extension ShendetThemeContext on BuildContext {
  ShendetPalette get palette =>
      Theme.of(this).extension<ShendetPalette>() ?? ShendetPalette.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

ThemeData buildLightTheme() =>
    _buildTheme(ShendetPalette.light, Brightness.light);

ThemeData buildDarkTheme() => _buildTheme(ShendetPalette.dark, Brightness.dark);

ThemeData _buildTheme(ShendetPalette p, Brightness brightness) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: brightness,
      ).copyWith(
        primary: p.primary,
        onPrimary: p.onPrimary,
        secondary: p.primaryLight,
        surface: p.surface,
        onSurface: p.ink,
        onSurfaceVariant: p.muted,
        outline: p.line,
        outlineVariant: p.line,
        surfaceContainerLowest: p.background,
        surfaceContainerLow: p.background,
        surfaceContainer: p.surfaceAlt,
        surfaceContainerHigh: p.surfaceAlt,
        surfaceContainerHighest: p.surfaceAlt,
        error: p.emergency,
      );

  final textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 34,
      height: 40 / 34,
      fontWeight: FontWeight.w800,
      color: p.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 36 / 28,
      fontWeight: FontWeight.w700,
      color: p.ink,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.w700,
      color: p.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 26 / 20,
      fontWeight: FontWeight.w700,
      color: p.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight.w600,
      color: p.ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 24 / 16, color: p.ink),
    bodyMedium: TextStyle(fontSize: 14, height: 20 / 14, color: p.muted),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
      color: p.ink,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      color: p.muted,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    canvasColor: p.background,
    shadowColor: p.shadow,
    fontFamily: 'Inter',
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    extensions: [p],
    iconTheme: IconThemeData(color: p.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      foregroundColor: p.ink,
      iconTheme: IconThemeData(color: p.ink),
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: p.ink,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: p.mint,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? p.primaryDark
              : p.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? p.primaryDark
              : p.muted,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        disabledBackgroundColor: p.line,
        disabledForegroundColor: p.muted,
        minimumSize: const Size.fromHeight(54),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.primary,
        minimumSize: const Size.fromHeight(54),
        side: BorderSide(color: p.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        minimumSize: const Size(kTouchTarget, kTouchTarget),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      hintStyle: TextStyle(color: p.muted),
      labelStyle: TextStyle(color: p.muted),
      prefixIconColor: p.muted,
      suffixIconColor: p.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: p.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: p.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: p.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: p.emergency),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: p.emergency, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: p.line),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      side: BorderSide(color: p.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      labelStyle: TextStyle(color: p.ink, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.inverseSurface,
      contentTextStyle: TextStyle(color: p.onInverse),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      modalBackgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: p.line,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    listTileTheme: ListTileThemeData(iconColor: p.muted, textColor: p.ink),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? p.primary
            : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(p.onPrimary),
      side: BorderSide(color: p.line, width: 1.6),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? Colors.transparent : p.line,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: p.line)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.mint : p.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.primaryDark : p.muted,
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.primary,
      selectionColor: p.mint.withValues(alpha: 0.6),
      selectionHandleColor: p.primary,
    ),
  );
}
