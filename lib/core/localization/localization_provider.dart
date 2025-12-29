import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for SharedPreferences (ensure it's initialized in main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// Key used for storing language preference
const String _languageCodeKey = 'languageCode';
const String _countryCodeKey = 'countryCode';

/// Supported locales in the app
class SupportedLocales {
  static const Locale english = Locale('en');
  static const Locale arabic = Locale('ar');

  static const List<Locale> all = [english, arabic];

  /// Check if a locale is supported
  static bool isSupported(Locale locale) {
    return all.any((l) => l.languageCode == locale.languageCode);
  }

  /// Get the closest supported locale for a given locale
  static Locale getClosestSupported(Locale locale) {
    // Try exact match first
    for (final supported in all) {
      if (supported.languageCode == locale.languageCode) {
        return supported;
      }
    }
    // Default to English
    return english;
  }
}

/// Service for managing app locale with persistence
class LocalizationService extends Notifier<Locale> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Locale build() {
    return _loadInitialLocale();
  }

  /// Load the initial locale from preferences or system
  Locale _loadInitialLocale() {
    final savedCode = _prefs.getString(_languageCodeKey);
    final savedCountry = _prefs.getString(_countryCodeKey);

    if (savedCode != null) {
      final savedLocale = Locale(savedCode, savedCountry);
      if (SupportedLocales.isSupported(savedLocale)) {
        return savedLocale;
      }
    }

    // Fall back to system locale if supported
    return _getSystemLocaleOrDefault();
  }

  /// Get system locale or default to English
  Locale _getSystemLocaleOrDefault() {
    try {
      final systemLocale = _getSystemLocale();
      if (SupportedLocales.isSupported(systemLocale)) {
        return SupportedLocales.getClosestSupported(systemLocale);
      }
    } catch (_) {
      // Ignore errors getting system locale
    }
    return SupportedLocales.english;
  }

  /// Gets the system locale
  Locale _getSystemLocale() {
    try {
      final String localeName = Platform.localeName;
      final parts = localeName.split('_');
      if (parts.isNotEmpty) {
        return Locale(parts[0], parts.length > 1 ? parts[1] : null);
      }
    } catch (_) {
      // Platform.localeName might not be available
    }
    return SupportedLocales.english;
  }

  /// Set the app locale and persist it
  Future<void> setLocale(Locale locale) async {
    if (!SupportedLocales.isSupported(locale)) {
      locale = SupportedLocales.getClosestSupported(locale);
    }

    state = locale;
    await _prefs.setString(_languageCodeKey, locale.languageCode);
    if (locale.countryCode != null) {
      await _prefs.setString(_countryCodeKey, locale.countryCode!);
    } else {
      await _prefs.remove(_countryCodeKey);
    }
  }

  /// Toggle between English and Arabic
  Future<void> toggleLocale() async {
    final newLocale = isArabic
        ? SupportedLocales.english
        : SupportedLocales.arabic;
    await setLocale(newLocale);
  }

  /// Reset to system locale
  Future<void> resetToSystemLocale() async {
    await _prefs.remove(_languageCodeKey);
    await _prefs.remove(_countryCodeKey);
    state = _getSystemLocaleOrDefault();
  }

  /// Check if current locale is RTL
  bool get isRtl => state.languageCode == 'ar';

  /// Check if current locale is Arabic
  bool get isArabic => state.languageCode == 'ar';

  /// Check if current locale is English
  bool get isEnglish => state.languageCode == 'en';

  /// Get text direction based on current locale
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// Get the language name in its native form
  String get currentLanguageName {
    switch (state.languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
      default:
        return 'English';
    }
  }
}

/// Main provider for localization
final localizationProvider = NotifierProvider<LocalizationService, Locale>(
  LocalizationService.new,
);

/// Provider to check if current locale is RTL
final isRtlProvider = Provider<bool>((ref) {
  final locale = ref.watch(localizationProvider);
  return locale.languageCode == 'ar';
});

/// Provider to get current text direction
final textDirectionProvider = Provider<TextDirection>((ref) {
  final isRtl = ref.watch(isRtlProvider);
  return isRtl ? TextDirection.rtl : TextDirection.ltr;
});
