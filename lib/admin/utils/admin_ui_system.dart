import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/phobes_theme.dart';

class AdminUISystem {
  // Dynamic Accent Colors (Sync with Project)
  static Color kNeonPurple(BuildContext context) => PhobesTheme.userAccentColor.value;
  static Color kElectricBlue(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color kCyberPink(BuildContext context) => PhobesTheme.accentColor;
  static Color kAccentBlue(BuildContext context) => PhobesTheme.kInfoColor;

  static LinearGradient primaryGradient(BuildContext context) {
    return PhobesTheme.primaryGradient;
  }

  static LinearGradient cyberGradient(BuildContext context) {
    return LinearGradient(
      colors: [PhobesTheme.userAccentColor.value, PhobesTheme.accentColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Decorations
  static BoxDecoration glassDecoration(BuildContext context, {double opacity = 0.08, double blur = 20}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? Colors.white.withOpacity(opacity) : Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        width: 1.5,
      ),
    );
  }

  static BoxDecoration cardDecoration(BuildContext context, {Color? borderColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;
    final cs = Theme.of(context).colorScheme;
    
    return BoxDecoration(
      color: isDark 
          ? (isAmoled ? const Color(0xFF0A0A0A) : const Color(0xFF1E293B)) 
          : Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.4) : cs.shadow.withOpacity(0.06),
          blurRadius: 30,
          offset: const Offset(0, 8),
        ),
      ],
      border: Border.all(
        color: borderColor ?? (isDark ? Colors.white.withOpacity(0.04) : cs.outline.withOpacity(0.08)),
        width: 1.2,
      ),
    );
  }

  // Text Styles
  static TextStyle titleStyle = GoogleFonts.outfit(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
  );

  static TextStyle subtitleStyle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GoogleFonts.outfit(
      fontSize: 14,
      color: cs.onSurface.withOpacity(0.55),
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle cardTitle = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  // Components
  static Widget buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
    bool isPositive = true,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 14,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: subtitleStyle(context),
          ),
        ],
      ),
    );
  }

  // Snackbar Methods
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  static bool isAdminMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 900;

  static bool isAdminCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static double horizontalPadding(BuildContext context) =>
      isAdminMobile(context) ? 16 : 24;

  static const List<String> adminNavTitles = [
    'Dashboard',
    'Kullanıcılar',
    'Etkileşim',
    'Sistem',
  ];

  static Future<T?> showAdaptiveDialog<T>({
    required BuildContext context,
    required Widget child,
  }) {
    if (isAdminCompact(context)) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: child,
        ),
      );
    }
    return showDialog<T>(context: context, builder: (_) => child);
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }
}
