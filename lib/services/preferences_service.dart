import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class PreferencesService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static String? getActiveGroupId() {
    return _prefs?.getString(AppConstants.keyActiveGroupId);
  }

  static Future<void> setActiveGroupId(String groupId) async {
    await _prefs?.setString(AppConstants.keyActiveGroupId, groupId);
  }

  static bool isAutoSyncEnabled() {
    return _prefs?.getBool(AppConstants.keyAutoSync) ?? true;
  }

  static Future<void> setAutoSyncEnabled(bool enabled) async {
    await _prefs?.setBool(AppConstants.keyAutoSync, enabled);
  }

  static String? getLastSyncTime() {
    return _prefs?.getString(AppConstants.keyLastSyncTime);
  }

  static Future<void> setLastSyncTime(String isoTime) async {
    await _prefs?.setString(AppConstants.keyLastSyncTime, isoTime);
  }

  static String getCurrencySymbol() {
    return _prefs?.getString(AppConstants.keyCurrencySymbol) ?? '₹';
  }

  static Future<void> setCurrencySymbol(String symbol) async {
    await _prefs?.setString(AppConstants.keyCurrencySymbol, symbol);
  }

  static bool isDarkMode() {
    return _prefs?.getBool(AppConstants.keyDarkMode) ?? false;
  }

  static Future<void> setDarkMode(bool isDark) async {
    await _prefs?.setBool(AppConstants.keyDarkMode, isDark);
  }

  static String? getUserEmail() {
    return _prefs?.getString(AppConstants.keyUserEmail);
  }

  static Future<void> setUserEmail(String? email) async {
    if (email == null) {
      await _prefs?.remove(AppConstants.keyUserEmail);
    } else {
      await _prefs?.setString(AppConstants.keyUserEmail, email);
    }
  }

  static String? getUserName() {
    return _prefs?.getString(AppConstants.keyUserName);
  }

  static Future<void> setUserName(String? name) async {
    if (name == null) {
      await _prefs?.remove(AppConstants.keyUserName);
    } else {
      await _prefs?.setString(AppConstants.keyUserName, name);
    }
  }
}
