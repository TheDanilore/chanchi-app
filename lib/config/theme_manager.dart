import 'package:flutter/material.dart';

class ThemeManager extends InheritedWidget {
  final ThemeData themeData;
  final ValueChanged<ThemeData> onThemeChanged;

  const ThemeManager({
    super.key,
    required this.themeData,
    required this.onThemeChanged,
    required super.child,
  });

  static ThemeManager of(BuildContext context) {
    final instance = context.dependOnInheritedWidgetOfExactType<ThemeManager>();
    assert(instance != null, "No ThemeManager found in the context");
    return instance!;
  }

  void changeTheme(ThemeData theme) {
    onThemeChanged(theme);
  }

  @override
  bool updateShouldNotify(covariant ThemeManager oldWidget) {
    return oldWidget.themeData != themeData;
  }
}
