/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flauncher/providers/network_diagnostics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _crashReportsEnabledKey = "crash_reports_enabled";
const _analyticsEnabledKey = "analytics_enabled";
const _use24HourTimeFormatKey = "use_24_hour_time_format";
const _appHighlightAnimationEnabledKey = "app_highlight_animation_enabled";
const _gradientUuidKey = "gradient_uuid";
const _unsplashEnabledKey = "unsplash_enabled";
const _unsplashAuthorKey = "unsplash_author";
const _languageCodeKey = "language_code";
const _recentPackagesKey = "recent_packages";
const _remoteShortcutsKey = "remote_shortcuts";
const _lastNetworkDiagnosticsKey = "last_network_diagnostics";
const _showDateKey = "show_date";
const _showNetworkStatusKey = "show_network_status";
const _showLocalIpAddressKey = "show_local_ip_address";
const _showNextAlarmKey = "show_next_alarm";
const _showWeatherKey = "show_weather";
const _screensaverGradientKey = "screensaver_gradient";
const _maxRecentPackages = 5;

class SettingsService extends ChangeNotifier {
  final SharedPreferences _sharedPreferences;
  final FirebaseCrashlytics _firebaseCrashlytics;
  final FirebaseAnalytics _firebaseAnalytics;
  final FirebaseRemoteConfig _firebaseRemoteConfig;
  late final Timer _remoteConfigRefreshTimer;

  bool get crashReportsEnabled =>
      _sharedPreferences.getBool(_crashReportsEnabledKey) ?? true;

  bool get analyticsEnabled =>
      _sharedPreferences.getBool(_analyticsEnabledKey) ?? true;

  bool get use24HourTimeFormat =>
      _sharedPreferences.getBool(_use24HourTimeFormatKey) ?? true;

  bool get appHighlightAnimationEnabled =>
      _sharedPreferences.getBool(_appHighlightAnimationEnabledKey) ?? true;

  String? get gradientUuid => _sharedPreferences.getString(_gradientUuidKey);

  bool get unsplashEnabled =>
      _firebaseRemoteConfig.getBool(_unsplashEnabledKey);

  String? get unsplashAuthor =>
      _sharedPreferences.getString(_unsplashAuthorKey);

  String? get languageCode => _sharedPreferences.getString(_languageCodeKey);

  bool get showDate => _sharedPreferences.getBool(_showDateKey) ?? true;

  bool get showNetworkStatus =>
      _sharedPreferences.getBool(_showNetworkStatusKey) ?? true;

  bool get showLocalIpAddress =>
      _sharedPreferences.getBool(_showLocalIpAddressKey) ?? true;

  Future<void> setShowDate(bool value) async {
    await _sharedPreferences.setBool(_showDateKey, value);
    notifyListeners();
  }

  Future<void> setShowNetworkStatus(bool value) async {
    await _sharedPreferences.setBool(_showNetworkStatusKey, value);
    notifyListeners();
  }

  Future<void> setShowLocalIpAddress(bool value) async {
    await _sharedPreferences.setBool(_showLocalIpAddressKey, value);
    notifyListeners();
  }

  bool get showNextAlarm =>
      _sharedPreferences.getBool(_showNextAlarmKey) ?? true;

  bool get showWeather => _sharedPreferences.getBool(_showWeatherKey) ?? false;

  String? get screensaverGradientUuid =>
      _sharedPreferences.getString(_screensaverGradientKey);

  Future<void> setShowNextAlarm(bool value) async {
    await _sharedPreferences.setBool(_showNextAlarmKey, value);
    notifyListeners();
  }

  Future<void> setShowWeather(bool value) async {
    await _sharedPreferences.setBool(_showWeatherKey, value);
    notifyListeners();
  }

  Future<void> setScreensaverGradientUuid(String? value) async {
    if (value == null) {
      await _sharedPreferences.remove(_screensaverGradientKey);
    } else {
      await _sharedPreferences.setString(_screensaverGradientKey, value);
    }
    notifyListeners();
  }

  Future<void> clearRecentPackages() async {
    await _sharedPreferences.remove(_recentPackagesKey);
    notifyListeners();
  }

  Map<String, dynamic> backupPreferences() => {
        "use24HourTimeFormat": use24HourTimeFormat,
        "showDate": showDate,
        "showNetworkStatus": showNetworkStatus,
        "showLocalIpAddress": showLocalIpAddress,
        "showNextAlarm": showNextAlarm,
        "showWeather": showWeather,
        "screensaverGradientUuid": screensaverGradientUuid,
        "appHighlightAnimationEnabled": appHighlightAnimationEnabled,
        "languageCode": languageCode,
      };

  Future<void> applyPreferences(Map<String, dynamic> preferences) async {
    Future<void> writeBool(String key, String prefKey) async {
      final value = preferences[key];
      if (value is bool) await _sharedPreferences.setBool(prefKey, value);
    }

    await writeBool("use24HourTimeFormat", _use24HourTimeFormatKey);
    await writeBool("showDate", _showDateKey);
    await writeBool("showNetworkStatus", _showNetworkStatusKey);
    await writeBool("showLocalIpAddress", _showLocalIpAddressKey);
    await writeBool("showNextAlarm", _showNextAlarmKey);
    await writeBool("showWeather", _showWeatherKey);
    await writeBool(
        "appHighlightAnimationEnabled", _appHighlightAnimationEnabledKey);
    final gradient = preferences["screensaverGradientUuid"];
    if (gradient is String) {
      await _sharedPreferences.setString(_screensaverGradientKey, gradient);
    } else if (preferences.containsKey("screensaverGradientUuid")) {
      await _sharedPreferences.remove(_screensaverGradientKey);
    }
    final language = preferences["languageCode"];
    if (language is String) {
      await _sharedPreferences.setString(_languageCodeKey, language);
    } else if (preferences.containsKey("languageCode")) {
      await _sharedPreferences.remove(_languageCodeKey);
    }
    notifyListeners();
  }

  /// Most recently launched package names, latest first.
  List<String> get recentPackages =>
      _sharedPreferences.getStringList(_recentPackagesKey) ?? [];

  Map<int, String> get remoteShortcuts {
    final saved = _sharedPreferences.getString(_remoteShortcutsKey);
    if (saved == null) return {};
    return (jsonDecode(saved) as Map<String, dynamic>)
        .map((key, value) => MapEntry(int.parse(key), value as String));
  }

  NetworkDiagnosticsResult? get lastNetworkDiagnostics =>
      NetworkDiagnosticsResult.tryFromJson(
          _sharedPreferences.getString(_lastNetworkDiagnosticsKey));

  Future<void> setLastNetworkDiagnostics(
      NetworkDiagnosticsResult result) async {
    await _sharedPreferences.setString(
        _lastNetworkDiagnosticsKey, jsonEncode(result.toJson()));
    notifyListeners();
  }

  SettingsService(
    this._sharedPreferences,
    this._firebaseCrashlytics,
    this._firebaseAnalytics,
    this._firebaseRemoteConfig,
  ) {
    _firebaseCrashlytics
        .setCrashlyticsCollectionEnabled(kReleaseMode && crashReportsEnabled);
    _firebaseAnalytics
        .setAnalyticsCollectionEnabled(kReleaseMode && analyticsEnabled);
    _remoteConfigRefreshTimer = Timer.periodic(
        Duration(hours: 6, minutes: 1), (_) => _refreshFirebaseRemoteConfig());
  }

  @override
  void dispose() {
    _remoteConfigRefreshTimer.cancel();
    super.dispose();
  }

  Future<void> setCrashReportsEnabled(bool value) async {
    _firebaseCrashlytics.setCrashlyticsCollectionEnabled(kReleaseMode && value);
    await _sharedPreferences.setBool(_crashReportsEnabledKey, value);
    notifyListeners();
  }

  Future<void> setAnalyticsEnabled(bool value) async {
    _firebaseAnalytics.setAnalyticsCollectionEnabled(kReleaseMode && value);
    await _sharedPreferences.setBool(_analyticsEnabledKey, value);
    notifyListeners();
  }

  Future<void> setUse24HourTimeFormat(bool value) async {
    await _sharedPreferences.setBool(_use24HourTimeFormatKey, value);
    notifyListeners();
  }

  Future<void> setAppHighlightAnimationEnabled(bool value) async {
    await _sharedPreferences.setBool(_appHighlightAnimationEnabledKey, value);
    notifyListeners();
  }

  Future<void> setGradientUuid(String value) async {
    await _sharedPreferences.setString(_gradientUuidKey, value);
    notifyListeners();
  }

  Future<void> setUnsplashAuthor(String? value) async {
    if (value == null) {
      await _sharedPreferences.remove(_unsplashAuthorKey);
    } else {
      await _sharedPreferences.setString(_unsplashAuthorKey, value);
    }
    notifyListeners();
  }

  Future<void> setLanguageCode(String? value) async {
    if (value == null) {
      await _sharedPreferences.remove(_languageCodeKey);
    } else {
      await _sharedPreferences.setString(_languageCodeKey, value);
    }
    notifyListeners();
  }

  Future<void> addRecentPackage(String packageName) async {
    final recents = recentPackages..remove(packageName);
    recents.insert(0, packageName);
    await _sharedPreferences.setStringList(
        _recentPackagesKey, recents.take(_maxRecentPackages).toList());
    notifyListeners();
  }

  Future<void> setRemoteShortcut(int keyCode, String packageName) async {
    final shortcuts = Map<int, String>.from(remoteShortcuts);
    shortcuts[keyCode] = packageName;
    await _saveRemoteShortcuts(shortcuts);
  }

  Future<void> removeRemoteShortcut(int keyCode) async {
    final shortcuts = Map<int, String>.from(remoteShortcuts)..remove(keyCode);
    await _saveRemoteShortcuts(shortcuts);
  }

  Future<void> _saveRemoteShortcuts(Map<int, String> shortcuts) async {
    final encoded =
        shortcuts.map((key, value) => MapEntry(key.toString(), value));
    await _sharedPreferences.setString(
        _remoteShortcutsKey, jsonEncode(encoded));
    notifyListeners();
  }

  Future<void> _refreshFirebaseRemoteConfig() async {
    bool updated = false;
    try {
      updated = await _firebaseRemoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint("Could not refresh Firebase Remote Config: $e");
    }
    if (updated) {
      notifyListeners();
    }
  }
}
