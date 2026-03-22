import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhobesTheme {
  PhobesTheme._();

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.dark);

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  static Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (saved != null) {
      switch (saved) {
        case 'light':
          themeMode.value = ThemeMode.light;
        case 'dark':
          themeMode.value = ThemeMode.dark;
        case 'system':
          themeMode.value = ThemeMode.system;
      }
    }
  }

  static void toggleTheme() {
    themeMode.value =
        themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  static final ValueNotifier<bool> amoledMode = ValueNotifier(false);

  static Future<void> setAmoledMode(bool enabled) async {
    amoledMode.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('amoled_mode', enabled);
    themeMode.value = themeMode.value;
  }

  static Future<void> loadAmoledMode() async {
    final prefs = await SharedPreferences.getInstance();
    amoledMode.value = prefs.getBool('amoled_mode') ?? false;
  }

  static final ValueNotifier<Color> userAccentColor =
      ValueNotifier(kPrimaryColor);

  static Future<void> setAccentColor(Color color) async {
    userAccentColor.value = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent_color', color.toARGB32());
    themeMode.value = themeMode.value;
  }

  static Future<void> loadAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('accent_color');
    if (saved != null) {
      userAccentColor.value = Color(saved);
    }
  }

  static Future<void> loadAllPreferences() async {
    await loadSavedTheme();
    await loadAmoledMode();
    await loadAccentColor();
  }

  static const List<Color> accentColorOptions = [
    kPrimaryColor,
    Color(0xFF3B82F6),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFFF472B6),
    Color(0xFFE65100),
  ];

  static const Color kPrimaryColor = Color(0xFF8B5CF6);
  static const Color kSecondaryColor = Color(0xFF10B981);
  static const Color kAccentColor = Color(0xFFF472B6);
  static const Color kTertiaryColor = Color(0xFF06B6D4);

  static const Color kDarkBackground = Color(0xFF050505);
  static const Color kDarkSurface = Color(0xFF121212);
  static const Color kDarkSurfaceLight = Color(0xFF1E1E1E);
  static const Color kDarkSurfaceContainer = Color(0xFF2A2A2A);

  static const Color kAmoledBackground = Color(0xFF000000);
  static const Color kAmoledSurface = Color(0xFF0A0A0A);
  static const Color kAmoledSurfaceLight = Color(0xFF141414);

  static const Color kLightBackground = Color(0xFFF8FAFC);
  static const Color kLightSurface = Color(0xFFFFFFFF);
  static const Color kLightSurfaceDark = Color(0xFFF1F5F9);
  static const Color kLightSurfaceContainer = Color(0xFFE2E8F0);

  static const Color kErrorColor = Color(0xFFEF4444);
  static const Color kSuccessColor = Color(0xFF10B981);
  static const Color kWarningColor = Color(0xFFF59E0B);
  static const Color kInfoColor = Color(0xFF3B82F6);

  static const Color todayHighlight = Color(0xFFE65100);

  static const Color primaryColor = kPrimaryColor;
  static const Color secondaryColor = kSecondaryColor;
  static const Color accentColor = kAccentColor;
  static const Color backgroundColor = kDarkBackground;
  static const Color surfaceColor = kDarkSurface;
  static const Color cardColor = kDarkSurfaceLight;
  static const Color dialogColor = kDarkSurface;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white54;
  static const Color errorColor = kErrorColor;
  static const Color successColor = kSuccessColor;

  static ThemeData get darkTheme => _buildDarkTheme(
        background: amoledMode.value ? kAmoledBackground : kDarkBackground,
        surface: amoledMode.value ? kAmoledSurface : kDarkSurface,
        surfaceLight:
            amoledMode.value ? kAmoledSurfaceLight : kDarkSurfaceLight,
      );

  static ThemeData get lightTheme => _buildLightTheme();

  static ThemeData _buildDarkTheme({
    required Color background,
    required Color surface,
    required Color surfaceLight,
  }) {
    final accent = userAccentColor.value;
    final colorScheme = ColorScheme.dark(
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: accent.withValues(alpha: 0.2),
      onPrimaryContainer: accent,
      secondary: kSecondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: kSecondaryColor.withValues(alpha: 0.2),
      onSecondaryContainer: kSecondaryColor,
      tertiary: kTertiaryColor,
      onTertiary: Colors.white,
      surface: surface,
      onSurface: Colors.white,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: surfaceLight,
      surfaceContainerHigh: kDarkSurfaceContainer,
      error: kErrorColor,
      onError: Colors.white,
      outline: Colors.white12,
      outlineVariant: Colors.white10,
      shadow: Colors.black,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackground: background,
      dividerColor: Colors.white10,
      iconColor: Colors.white70,
      statusBarStyle: SystemUiOverlayStyle.light,
    );
  }

  static ThemeData _buildLightTheme() {
    final accent = userAccentColor.value;
    final colorScheme = ColorScheme.light(
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: accent.withValues(alpha: 0.1),
      onPrimaryContainer: accent,
      secondary: kSecondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: kSecondaryColor.withValues(alpha: 0.1),
      onSecondaryContainer: kSecondaryColor,
      tertiary: kTertiaryColor,
      onTertiary: Colors.white,
      surface: kLightSurface,
      onSurface: const Color(0xFF1E293B),
      surfaceContainerLowest: kLightBackground,
      surfaceContainerLow: kLightSurface,
      surfaceContainer: kLightSurfaceDark,
      surfaceContainerHigh: kLightSurfaceContainer,
      error: kErrorColor,
      onError: Colors.white,
      outline: Colors.black12,
      outlineVariant: Colors.black.withValues(alpha: 0.06),
      shadow: Colors.black26,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackground: kLightBackground,
      dividerColor: Colors.black12,
      iconColor: const Color(0xFF64748B),
      statusBarStyle: SystemUiOverlayStyle.dark,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Brightness brightness,
    required Color scaffoldBackground,
    required Color dividerColor,
    required Color iconColor,
    required SystemUiOverlayStyle statusBarStyle,
  }) {
    final isDark = brightness == Brightness.dark;
    final baseTextTheme =
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.outfitTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      labelMedium: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      labelSmall: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface.withValues(alpha: 0.5),
        letterSpacing: 0.5,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      primaryColor: colorScheme.primary,
      canvasColor: colorScheme.surface,
      cardColor: colorScheme.surfaceContainer,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: statusBarStyle,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary);
          }
          return IconThemeData(
              color: colorScheme.onSurface.withValues(alpha: 0.5));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            );
          }
          return GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme:
            IconThemeData(color: colorScheme.onSurface.withValues(alpha: 0.5)),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: isDark ? 0 : 1,
        shadowColor: isDark ? Colors.transparent : Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusL),
          side: isDark
              ? BorderSide(color: colorScheme.outline, width: 0.5)
              : BorderSide.none,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusXL),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: colorScheme.onSurface.withValues(alpha: 0.2),
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusM),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusM),
          ),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusS),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusL),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusM),
          borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.3), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusM),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusM),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        hintStyle: GoogleFonts.outfit(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.outfit(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedColor: colorScheme.primary.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusS),
          side: BorderSide(color: colorScheme.outline, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? colorScheme.surfaceContainerHigh : const Color(0xFF323232),
        contentTextStyle: GoogleFonts.outfit(
          color: isDark ? colorScheme.onSurface : Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusM),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: colorScheme.primary,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.5),
        labelStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicatorSize: TabBarIndicatorSize.label,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.onSurface.withValues(alpha: 0.4);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.3);
          }
          return colorScheme.surfaceContainerHigh;
        }),
      ),
      dividerColor: dividerColor,
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 0.5,
        space: 0,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusM),
        ),
        iconColor: iconColor,
        textColor: colorScheme.onSurface,
      ),
      iconTheme: IconThemeData(color: iconColor, size: 24),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(borderRadiusS),
        ),
        textStyle: GoogleFonts.outfit(
          color: colorScheme.onSurface,
          fontSize: 12,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withValues(alpha: 0.15),
        circularTrackColor: colorScheme.primary.withValues(alpha: 0.15),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusM),
        ),
        textStyle: GoogleFonts.outfit(
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.15),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.1),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(false),
        trackVisibility: WidgetStateProperty.all(false),
        thickness: WidgetStateProperty.all(0),
        thumbColor: WidgetStateProperty.all(Colors.transparent),
        radius: const Radius.circular(10),
      ),
    );
  }

  static LinearGradient get primaryGradient => LinearGradient(
        colors: [
          userAccentColor.value,
          HSLColor.fromColor(userAccentColor.value)
              .withLightness(
                  (HSLColor.fromColor(userAccentColor.value).lightness - 0.1)
                      .clamp(0.0, 1.0))
              .toColor(),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient todayGradient = LinearGradient(
    colors: [Color(0xFFE65100), Color(0xFFEF6C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient cardGradient(bool isDark) => LinearGradient(
        colors: isDark
            ? [const Color(0xFF212121), const Color(0xFF181818)]
            : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient glassGradient(bool isDark) => LinearGradient(
        colors: isDark
            ? [
                const Color(0x1FFFFFFF),
                const Color(0x05FFFFFF),
              ]
            : [
                const Color(0xCCFFFFFF),
                const Color(0x88FFFFFF),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF212121), Color(0xFF181818)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientDark = LinearGradient(
    colors: [Color(0x1FFFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientLight = LinearGradient(
    colors: [Color(0xCCFFFFFF), Color(0x88FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> glowShadow(Color color, {double intensity = 0.4}) => [
        BoxShadow(
          color: color.withValues(alpha: intensity),
          blurRadius: 20,
          spreadRadius: -5,
        ),
      ];

  static List<BoxShadow> getCardShadow(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    }
  }

  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: userAccentColor.value.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -2,
        ),
      ];

  static BorderRadius defaultRadius = BorderRadius.circular(20);

  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animVerySlow = Duration(milliseconds: 800);

  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveBounce = Curves.elasticOut;
  static const Curve curveSmooth = Curves.easeInOutCubic;
  static const Curve curveSharp = Curves.easeOutExpo;

  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;
  static const double spacingXXXL = 48.0;

  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 24.0;
  static const double borderRadiusRound = 999.0;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

extension PhobesThemeExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  double get screenWidth => MediaQuery.sizeOf(this).width;

  double get screenHeight => MediaQuery.sizeOf(this).height;
}
