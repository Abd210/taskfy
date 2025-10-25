import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme definitions with beautiful gradients
  static final Map<String, ThemeConfig> themes = {
    'white': ThemeConfig(
      name: 'Clean White',
      gradient: [Color(0xFFfafafa), Color(0xFFe3e4e8)],
      primary: Color(0xFF2563eb),
      secondary: Color(0xFF3b82f6),
      accent: Color(0xFF60a5fa),
      cardGradient: [Color(0xFFffffff), Color(0xFFf8f9fa)],
      isDark: false,
    ),
    'purple': ThemeConfig(
      name: 'Purple Dream',
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
      primary: Color(0xFF667eea),
      secondary: Color(0xFF764ba2),
      accent: Color(0xFFf093fb),
      cardGradient: [Color(0xFFfdfbfb), Color(0xFFebedee)],
      isDark: false,
    ),
    'green': ThemeConfig(
      name: 'Nature',
      gradient: [Color(0xFF11998e), Color(0xFF38ef7d)],
      primary: Color(0xFF11998e),
      secondary: Color(0xFF38ef7d),
      accent: Color(0xFF06d6a0),
      cardGradient: [Color(0xFFf0fff4), Color(0xFFd5f4e6)],
      isDark: false,
    ),
    'pink': ThemeConfig(
      name: 'Rose Garden',
      gradient: [Color(0xFFf857a6), Color(0xFFff5858)],
      primary: Color(0xFFf857a6),
      secondary: Color(0xFFff5858),
      accent: Color(0xFFffc3a0),
      cardGradient: [Color(0xFFfff5f7), Color(0xFFfed7e2)],
      isDark: false,
    ),
    'black': ThemeConfig(
      name: 'Midnight',
      gradient: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
      primary: Color(0xFF302b63),
      secondary: Color(0xFF24243e),
      accent: Color(0xFF667eea),
      cardGradient: [Color(0xFF1a1a2e), Color(0xFF16213e)],
      isDark: true,
    ),
    'ocean': ThemeConfig(
      name: 'Ocean Breeze',
      gradient: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
      primary: Color(0xFF2E3192),
      secondary: Color(0xFF1BFFFF),
      accent: Color(0xFF4facfe),
      cardGradient: [Color(0xFFe0f7fa), Color(0xFFb2ebf2)],
      isDark: false,
    ),
  };

  static ThemeData themeFor(String key) {
    final config = themes[key] ?? themes['white']!;
    return _buildTheme(config);
  }

  static ThemeData _buildTheme(ThemeConfig config) {
    final base = ThemeData(useMaterial3: true, brightness: config.isDark ? Brightness.dark : Brightness.light);
    
    final textColor = config.isDark ? Colors.white : (config.name == 'Clean White' ? Colors.black : Color(0xFF1f2937));
    final subtextColor = config.isDark ? Colors.grey[300] : (config.name == 'Clean White' ? Color(0xFF4b5563) : Color(0xFF6b7280));
    final appBarTextColor = config.isDark ? Colors.white : (config.name == 'Clean White' ? Colors.black : Colors.white);
    
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: config.primary,
        brightness: config.isDark ? Brightness.dark : Brightness.light,
        primary: config.primary,
        secondary: config.secondary,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: textColor),
        titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, color: textColor),
        bodySmall: GoogleFonts.poppins(fontSize: 12, color: subtextColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: appBarTextColor,
        ),
        iconTheme: IconThemeData(color: appBarTextColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: config.isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: config.isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: config.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(color: subtextColor?.withOpacity(0.6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: config.primary.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: config.primary.withOpacity(0.3), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          foregroundColor: config.primary,
        ),
      ),
      iconTheme: IconThemeData(color: textColor),
      dividerColor: config.isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
      splashColor: config.accent.withOpacity(0.1),
      highlightColor: Colors.transparent,
    );
  }
}

class ThemeConfig {
  final String name;
  final List<Color> gradient;
  final Color primary;
  final Color secondary;
  final Color accent;
  final List<Color> cardGradient;
  final bool isDark;

  ThemeConfig({
    required this.name,
    required this.gradient,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.cardGradient,
    required this.isDark,
  });
}
