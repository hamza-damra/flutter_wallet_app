import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../models/category_model.dart';

/// Helper class for translating keys to localized strings.
/// This is used for translating database keys (like category names) to localized UI strings.
class TranslationHelper {
  /// Private constructor
  TranslationHelper._();

  /// Get localized category name from a CategoryModel.
  /// If the locale is Arabic and the category has an Arabic name, use that.
  /// If the key is a known localization key (e.g., "cat_food"), returns the localized string.
  /// Otherwise, returns the key as-is (for user-created categories).
  static String getCategoryNameFromModel(
    BuildContext context,
    CategoryModel category,
  ) {
    final locale = Localizations.localeOf(context);

    // For user-created categories with Arabic name, show Arabic when in Arabic locale
    if (locale.languageCode == 'ar' &&
        category.nameAr != null &&
        category.nameAr!.isNotEmpty) {
      return category.nameAr!;
    }

    // For system categories or English locale, use the regular translation
    return getCategoryName(context, category.name);
  }

  /// Get localized category name from a key or human-readable name.
  /// If the key is a known localization key (e.g., "cat_food"), returns the localized string.
  /// If the key is a human-readable name (e.g., "Food & Drinks"), maps it to a key first.
  /// Otherwise, returns the key as-is (for user-created categories).
  static String getCategoryName(BuildContext context, String key) {
    if (key.isEmpty) return _getUnknown(context);

    // If it's not a system key (starts with cat_), try to find one from the human-readable name
    String targetKey = key;
    if (!key.startsWith('cat_')) {
      final mappedKey = getCategoryKey(key);
      if (mappedKey != null) {
        targetKey = mappedKey;
      }
    }

    final l10n = AppLocalizations.of(context);

    // Map of keys to their localized getters
    switch (targetKey) {
      case 'cat_food':
        return l10n.cat_food;
      case 'cat_shopping':
        return l10n.cat_shopping;
      case 'cat_transportation':
        return l10n.cat_transportation;
      case 'cat_entertainment':
        return l10n.cat_entertainment;
      case 'cat_bills':
        return l10n.cat_bills;
      case 'cat_income':
        return l10n.cat_income;
      case 'cat_home':
        return l10n.cat_home;
      case 'cat_haircut':
        return l10n.cat_haircut;
      case 'cat_health':
        return l10n.cat_health;
      case 'cat_education':
        return l10n.cat_education;
      case 'cat_travel':
        return l10n.cat_travel;
      case 'cat_gift':
        return l10n.cat_gift;
      case 'cat_other':
        return l10n.cat_other;
      case 'cat_salary':
        return l10n.cat_salary;
      case 'cat_investment':
        return l10n.cat_investment;
      case 'cat_freelance':
        return l10n.cat_freelance;
      default:
        // Return the key itself for user-created categories
        return key;
    }
  }

  /// Check if a category key is a system/built-in category
  static bool isSystemCategory(String key) {
    return key.startsWith('cat_');
  }

  /// Get the localization key for a human-readable category name
  /// Used when creating default categories
  static String? getCategoryKey(String name) {
    final normalized = name.toLowerCase().trim();

    const mapping = {
      'food': 'cat_food',
      'food & drinks': 'cat_food',
      'shopping': 'cat_shopping',
      'transportation': 'cat_transportation',
      'entertainment': 'cat_entertainment',
      'bills': 'cat_bills',
      'income': 'cat_income',
      'home': 'cat_home',
      'hair cut': 'cat_haircut',
      'haircut': 'cat_haircut',
      'health': 'cat_health',
      'education': 'cat_education',
      'travel': 'cat_travel',
      'gift': 'cat_gift',
      'other': 'cat_other',
      'salary': 'cat_salary',
      'investment': 'cat_investment',
      'freelance': 'cat_freelance',
    };

    return mapping[normalized];
  }

  /// Get transaction type display name
  static String getTransactionType(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context);
    switch (type.toLowerCase()) {
      case 'income':
        return l10n.incomeType;
      case 'expense':
        return l10n.expenseType;
      default:
        return type;
    }
  }

  /// Gets a fallback "Unknown" string
  static String _getUnknown(BuildContext context) {
    // Fallback for unknown/empty keys
    return AppLocalizations.of(context).cat_other;
  }

  /// Utility method to get AppLocalizations safely
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations.of(context);
  }

  /// Check if the current context is using RTL language
  static bool isRtl(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }

  /// Get current text direction from context
  static TextDirection getTextDirection(BuildContext context) {
    return Directionality.of(context);
  }
}

/// Extension on BuildContext for easy access to localization
extension LocalizationExtension on BuildContext {
  /// Get AppLocalizations instance
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Check if current locale is RTL
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// Get current locale
  Locale get locale => Localizations.localeOf(this);

  /// Get current text direction
  TextDirection get textDirection => Directionality.of(this);
}
