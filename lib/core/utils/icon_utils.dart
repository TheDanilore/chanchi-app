import 'package:flutter/material.dart';

class IconUtils {
  /// A comprehensive map of icon names to their corresponding IconData
  static final Map<String, IconData> _iconMap = {
    // Common category icons
    'shopping_cart': Icons.shopping_cart,
    'restaurant': Icons.restaurant,
    'home': Icons.home,
    'directions_car': Icons.directions_car,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'sports_esports': Icons.sports_esports,
    'work': Icons.work,

    // Financial icons
    'credit_card': Icons.credit_card,
    'savings': Icons.savings,
    'attach_money': Icons.attach_money,
    'account_balance_wallet': Icons.account_balance_wallet,
    'category': Icons.category,
    'shop_sharp': Icons.shop_sharp,
    'payments': Icons.payments,
    'payment': Icons.payment,

    // Travel and miscellaneous icons
    'airplanemode_active_sharp': Icons.airplanemode_active_sharp,
    'cruelty_free_outlined': Icons.cruelty_free_outlined,

    // Additional common icons
    'food': Icons.fastfood,
    'entertainment': Icons.movie,
    'education': Icons.school_outlined,
    'health': Icons.health_and_safety,
    'transport': Icons.directions_bus,
    'gift': Icons.card_giftcard,
    'phone': Icons.phone,
    'computer': Icons.computer,
    'utilities': Icons.electrical_services,
    'pets': Icons.pets,
    'shopping': Icons.shopping_bag,
  };

  /// Get an icon based on the icon name
  ///
  /// [iconName] The name of the icon to retrieve
  /// [fallbackType] Optional parameter to provide a fallback icon based on a type (e.g., 'expense' or 'income')
  static IconData getIconByName(String? iconName, {String? fallbackType}) {
    // If iconName is provided and exists in the map, return that icon
    if (iconName != null && _iconMap.containsKey(iconName)) {
      return _iconMap[iconName]!;
    }

    // If no matching icon and a fallback type is provided
    if (fallbackType == 'expense') {
      return Icons.arrow_upward;
    } else if (fallbackType == 'income') {
      return Icons.arrow_downward;
    }

    // Default icon if no match is found
    return Icons.category_outlined;
  }

  /// Add a custom icon to the icon map
  ///
  /// Useful for dynamically adding new icons during runtime
  static void addCustomIcon(String iconName, IconData iconData) {
    _iconMap[iconName] = iconData;
  }

  /// Check if an icon exists in the map
  static bool hasIcon(String iconName) {
    return _iconMap.containsKey(iconName);
  }
}
