import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Open Finance Manager';
  static const String appVersion = '1.0.0';

  // Storage / Preferences Keys
  static const String keyActiveGroupId = 'active_group_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyAutoSync = 'auto_sync_enabled';
  static const String keyLastSyncTime = 'last_sync_time';
  static const String keyCurrencySymbol = 'currency_symbol';
  static const String keyDarkMode = 'dark_mode_enabled';

  // Default Categories with Icons
  static const List<Map<String, dynamic>> defaultExpenseCategories = [
    {'name': 'Food & Dining', 'icon': Icons.restaurant_rounded, 'color': 0xFFEF4444},
    {'name': 'Groceries & Milk', 'icon': Icons.local_grocery_store_rounded, 'color': 0xFFF59E0B},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_rounded, 'color': 0xFFEC4899},
    {'name': 'Transportation', 'icon': Icons.directions_car_rounded, 'color': 0xFF3B82F6},
    {'name': 'Bills & Utilities', 'icon': Icons.receipt_long_rounded, 'color': 0xFF8B5CF6},
    {'name': 'Entertainment', 'icon': Icons.movie_creation_rounded, 'color': 0xFF06B6D4},
    {'name': 'Health & Medical', 'icon': Icons.favorite_rounded, 'color': 0xFF10B981},
    {'name': 'Rent & Housing', 'icon': Icons.home_rounded, 'color': 0xFFF97316},
    {'name': 'Office & Business', 'icon': Icons.business_center_rounded, 'color': 0xFF6366F1},
    {'name': 'Others', 'icon': Icons.category_rounded, 'color': 0xFF64748B},
  ];

  static const List<Map<String, dynamic>> defaultIncomeCategories = [
    {'name': 'Salary', 'icon': Icons.account_balance_wallet_rounded, 'color': 0xFF10B981},
    {'name': 'Business Revenue', 'icon': Icons.storefront_rounded, 'color': 0xFF059669},
    {'name': 'Freelance', 'icon': Icons.laptop_mac_rounded, 'color': 0xFF3B82F6},
    {'name': 'Investment', 'icon': Icons.trending_up_rounded, 'color': 0xFF8B5CF6},
    {'name': 'Refund / Cashback', 'icon': Icons.replay_rounded, 'color': 0xFFF59E0B},
    {'name': 'Gift / Allowance', 'icon': Icons.card_giftcard_rounded, 'color': 0xFFEC4899},
    {'name': 'Others', 'icon': Icons.attach_money_rounded, 'color': 0xFF64748B},
  ];

  // Default Group Templates
  static const List<Map<String, dynamic>> presetGroups = [
    {
      'id': 'family_group',
      'name': 'Family',
      'description': 'Household expenses, groceries, school fees & bills',
      'iconCode': 0xe318, // Icons.home_rounded
      'colorValue': 0xFF3B82F6,
    },
    {
      'id': 'friends_group',
      'name': 'Friends',
      'description': 'Group outings, party splits, trips & dinners',
      'iconCode': 0xe2eb, // Icons.group_rounded
      'colorValue': 0xFF8B5CF6,
    },
    {
      'id': 'company_group',
      'name': 'Company',
      'description': 'Business operations, client payments & invoices',
      'iconCode': 0xe11e, // Icons.business_center_rounded
      'colorValue': 0xFF0F766E,
    },
    {
      'id': 'daily_milk_group',
      'name': 'Milk & Daily Needs',
      'description': 'Daily dairy supplies, newspapers & small recurring needs',
      'iconCode': 0xe3c0, // Icons.local_drink_rounded
      'colorValue': 0xFFF59E0B,
    },
  ];
}
