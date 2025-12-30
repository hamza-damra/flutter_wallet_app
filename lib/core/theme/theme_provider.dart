import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/localization_provider.dart';

/// Supported theme modes for the application
enum AppThemeMode { classic, modernDark, oceanBlue, glassy }

/// Theme provider to manage and persist the selected theme
final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<AppThemeMode> {
  static const _themeKey = 'selected_theme_mode';

  @override
  AppThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeName = prefs.getString(_themeKey);
    if (themeName != null) {
      try {
        return AppThemeMode.values.byName(themeName);
      } catch (_) {
        return AppThemeMode.classic;
      }
    }
    return AppThemeMode.classic;
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_themeKey, mode.name);
  }
}
