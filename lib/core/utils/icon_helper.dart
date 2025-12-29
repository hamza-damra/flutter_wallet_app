import 'package:flutter/material.dart';

/// Helper class for mapping icon names to IconData.
/// Used for dynamic icon resolution from database keys.
class IconHelper {
  /// Private constructor
  IconHelper._();

  /// Map of icon name keys to IconData
  static const Map<String, IconData> _iconMap = {
    // Category icons
    'food': Icons.fastfood,
    'shopping': Icons.shopping_cart,
    'transportation': Icons.directions_car,
    'entertainment': Icons.movie,
    'bills': Icons.receipt,
    'income': Icons.attach_money,
    'other': Icons.more_horiz,
    'hair cut': Icons.content_cut,
    'haircut': Icons.content_cut,
    'home': Icons.home,
    'health': Icons.medical_services,
    'education': Icons.school,
    'travel': Icons.flight,
    'gift': Icons.card_giftcard,
    'salary': Icons.account_balance_wallet,
    'investment': Icons.trending_up,
    'freelance': Icons.work_outline,

    // Navigation icons
    'back': Icons.arrow_back,
    'forward': Icons.arrow_forward,
    'menu': Icons.menu,
    'close': Icons.close,
    'add': Icons.add,
    'edit': Icons.edit,
    'delete': Icons.delete,
    'search': Icons.search,
    'settings': Icons.settings,
    'filter': Icons.filter_list,
    'sort': Icons.sort,

    // Action icons
    'save': Icons.save,
    'share': Icons.share,
    'download': Icons.download,
    'upload': Icons.upload,
    'refresh': Icons.refresh,
    'sync': Icons.sync,

    // Status icons
    'success': Icons.check_circle,
    'error': Icons.error,
    'warning': Icons.warning,
    'info': Icons.info,

    // User icons
    'user': Icons.person,
    'account': Icons.account_circle,
    'logout': Icons.logout,
    'login': Icons.login,

    // Misc icons
    'category': Icons.category,
    'wallet': Icons.account_balance_wallet,
    'money': Icons.monetization_on,
    'calendar': Icons.calendar_today,
    'time': Icons.access_time,
    'notification': Icons.notifications,
    'language': Icons.language,
    'theme': Icons.palette,
    'help': Icons.help,
    'about': Icons.info_outline,
  };

  /// Get IconData from an icon name key
  /// Returns a default category icon if not found
  static IconData getIcon(String iconName) {
    final normalized = iconName.toLowerCase().trim();
    return _iconMap[normalized] ?? Icons.category;
  }

  /// Get IconData with a custom fallback
  static IconData getIconOrDefault(String iconName, IconData defaultIcon) {
    final normalized = iconName.toLowerCase().trim();
    return _iconMap[normalized] ?? defaultIcon;
  }

  /// Check if an icon name is valid/known
  static bool isValidIcon(String iconName) {
    return _iconMap.containsKey(iconName.toLowerCase().trim());
  }

  /// Get all available category icons for selection UI
  static List<MapEntry<String, IconData>> getCategoryIcons() {
    return const [
      MapEntry('food', Icons.fastfood),
      MapEntry('shopping', Icons.shopping_cart),
      MapEntry('transportation', Icons.directions_car),
      MapEntry('entertainment', Icons.movie),
      MapEntry('bills', Icons.receipt),
      MapEntry('income', Icons.attach_money),
      MapEntry('home', Icons.home),
      MapEntry('hair cut', Icons.content_cut),
      MapEntry('health', Icons.medical_services),
      MapEntry('education', Icons.school),
      MapEntry('travel', Icons.flight),
      MapEntry('gift', Icons.card_giftcard),
      MapEntry('salary', Icons.account_balance_wallet),
      MapEntry('investment', Icons.trending_up),
      MapEntry('freelance', Icons.work_outline),
      MapEntry('other', Icons.more_horiz),
    ];
  }

  /// Get color for a transaction type
  static Color getTransactionColor(
    String type, {
    required Color incomeColor,
    required Color expenseColor,
  }) {
    return type.toLowerCase() == 'income' ? incomeColor : expenseColor;
  }

  /// Get arrow icon for transaction type
  static IconData getTransactionArrowIcon(String type) {
    return type.toLowerCase() == 'income'
        ? Icons.arrow_downward
        : Icons.arrow_upward;
  }
}
