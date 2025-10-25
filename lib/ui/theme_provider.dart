import 'package:flutter/material.dart';
import 'app_theme.dart';
// Conditional import: use web implementation on web, no-op elsewhere.
import '../utils/web_meta_stub.dart'
  if (dart.library.html) '../utils/web_meta_web.dart' as webmeta;

class ThemeProvider extends InheritedWidget {
  final String themeKey;
  final ThemeConfig config;

  ThemeProvider({
    super.key,
    required this.themeKey,
    required super.child,
  }) : config = AppTheme.themes[themeKey] ?? AppTheme.themes['purple']!;

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return themeKey != oldWidget.themeKey;
  }
}

class GradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final config = themeProvider?.config ?? AppTheme.themes['purple']!;

    // Update browser theme color and body background on web to match theme
    webmeta.applyThemeColors(config.gradient.first);

    final size = MediaQuery.of(context).size;
    return Container(
      width: double.infinity,
      height: size.height,
      decoration: BoxDecoration(
        color: config.gradient[0], // solid theme background
      ),
      child: Scaffold(
        backgroundColor: backgroundColor ?? Colors.transparent,
        extendBody: true,
        resizeToAvoidBottomInset: true,
        appBar: appBar,
        body: SafeArea(child: body),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
