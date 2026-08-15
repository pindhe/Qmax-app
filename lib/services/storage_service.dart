import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

class StorageService {
  StorageService(this._prefs, this._secure, this._box);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;
  final Box<dynamic> _box;

  static Future<StorageService> create() async {
    try {
      await Hive.initFlutter();
    } catch (_) {
      Hive.init('.');
    }
    final prefs = await SharedPreferences.getInstance();
    const secure = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final box = await Hive.openBox<dynamic>(HiveBoxes.app);
    return StorageService(prefs, secure, box);
  }

  Future<void> saveToken(String token) =>
      _secure.write(key: StorageKeys.accessToken, value: token);

  Future<String?> readToken() => _secure.read(key: StorageKeys.accessToken);

  Future<void> saveRefreshToken(String token) =>
      _secure.write(key: StorageKeys.refreshToken, value: token);

  Future<void> clearTokens() async {
    await _secure.delete(key: StorageKeys.accessToken);
    await _secure.delete(key: StorageKeys.refreshToken);
  }

  Future<void> setOnboardingComplete() =>
      _prefs.setBool(StorageKeys.onboardingComplete, true);

  bool get onboardingComplete =>
      _prefs.getBool(StorageKeys.onboardingComplete) ?? false;

  Future<void> setThemeMode(String value) =>
      _prefs.setString(StorageKeys.themeMode, value);

  String get themeMode => _prefs.getString(StorageKeys.themeMode) ?? 'system';

  Future<void> setLocale(String code) =>
      _prefs.setString(StorageKeys.locale, code);

  String? get locale => _prefs.getString(StorageKeys.locale);

  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(StorageKeys.notificationsEnabled, value);

  bool get notificationsEnabled =>
      _prefs.getBool(StorageKeys.notificationsEnabled) ?? true;

  Future<void> write(String key, String value) => _box.put(key, value);

  String? read(String key) => _box.get(key) as String?;

  Future<void> delete(String key) => _box.delete(key);

  Future<void> clearCache() async {
    await _box.delete(StorageKeys.cachedProducts);
    await _box.delete(StorageKeys.cachedCategories);
    await _box.delete(StorageKeys.cachedOrders);
  }
}
