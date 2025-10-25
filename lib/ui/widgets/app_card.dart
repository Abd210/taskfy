import 'package:flutter/material.dart';
import '../app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key, 
    this.padding = const EdgeInsets.all(16), 
    this.margin, 
    required this.child,
    this.themeKey,
  });

  final EdgeInsets padding;
  final EdgeInsets? margin;
  final Widget child;
  final String? themeKey;

  @override
  Widget build(BuildContext context) {
    // Get theme config from context or default
    final config = AppTheme.themes[themeKey] ?? AppTheme.themes['white']!;
    final isWhiteTheme = config.name == 'Clean White';
    
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: config.cardGradient[0], // Solid color instead of gradient
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWhiteTheme
            ? Colors.black.withOpacity(0.2)
            : (config.isDark 
              ? Colors.white.withOpacity(0.1) 
              : Colors.black.withOpacity(0.05)),
          width: isWhiteTheme ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isWhiteTheme 
              ? Colors.black.withOpacity(0.08)
              : config.primary.withOpacity(0.15),
            blurRadius: isWhiteTheme ? 12 : 20,
            offset: Offset(0, isWhiteTheme ? 4 : 8),
            spreadRadius: isWhiteTheme ? 0 : -4,
          ),
          BoxShadow(
            color: config.isDark 
              ? Colors.black.withOpacity(0.3) 
              : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
