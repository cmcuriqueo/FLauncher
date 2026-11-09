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

import 'package:flutter/services.dart';

class FLauncherChannel {
  static const _methodChannel = MethodChannel('me.efesser.flauncher/method');
  static const _eventChannel = EventChannel('me.efesser.flauncher/event');

  Future<List<dynamic>> getApplications() async =>
      (await _methodChannel.invokeListMethod('getApplications'))!;

  Future<bool> applicationExists(String packageName) async =>
      await _methodChannel.invokeMethod('applicationExists', packageName);

  Future<void> launchApp(String packageName) async =>
      await _methodChannel.invokeMethod('launchApp', packageName);

  Future<void> openSettings() async =>
      await _methodChannel.invokeMethod('openSettings');

  Future<void> openAppInfo(String packageName) async =>
      await _methodChannel.invokeMethod('openAppInfo', packageName);

  Future<void> uninstallApp(String packageName) async =>
      await _methodChannel.invokeMethod('uninstallApp', packageName);

  Future<void> forceStopApp(String packageName) async =>
      await _methodChannel.invokeMethod('forceStopApp', packageName);

  Future<bool> isDefaultLauncher() async =>
      await _methodChannel.invokeMethod('isDefaultLauncher');

  Future<bool> checkForGetContentAvailability() async =>
      await _methodChannel.invokeMethod("checkForGetContentAvailability");

  Future<void> startAmbientMode() async =>
      await _methodChannel.invokeMethod("startAmbientMode");

  Future<List<dynamic>> getWatchNextPrograms() async =>
      (await _methodChannel.invokeListMethod('getWatchNextPrograms'))!;

  Future<Map<String, dynamic>> getNetworkStatus() async =>
      Map<String, dynamic>.from(
          await _methodChannel.invokeMethod('getNetworkStatus'));

  Future<Map<String, dynamic>> getNetworkDetails() async =>
      Map<String, dynamic>.from(
          await _methodChannel.invokeMethod('getNetworkDetails'));

  Future<bool> openNetworkSettings() async =>
      await _methodChannel.invokeMethod('openNetworkSettings');

  Future<bool> openWifiSettings() async =>
      await _methodChannel.invokeMethod('openWifiSettings');

  Future<bool> openBluetoothSettings() async =>
      await _methodChannel.invokeMethod('openBluetoothSettings');

  Future<bool> lockScreen() async =>
      await _methodChannel.invokeMethod('lockScreen');

  Future<Map<String, dynamic>> getStorageStatus() async =>
      Map<String, dynamic>.from(
          await _methodChannel.invokeMethod('getStorageStatus'));

  Future<int?> getLauncherMemoryUsage() async {
    final value = await _methodChannel.invokeMethod('getLauncherMemoryUsage');
    return value is num ? value.toInt() : null;
  }

  Future<bool> openApplicationManagement() async =>
      await _methodChannel.invokeMethod('openApplicationManagement');

  Future<int?> getNextAlarm() async {
    final value = await _methodChannel.invokeMethod('getNextAlarm');
    if (value is int) return value;
    return null;
  }

  Future<Map<String, dynamic>?> getLastLocation() async {
    final value = await _methodChannel.invokeMethod('getLastLocation');
    if (value == null) return null;
    return Map<String, dynamic>.from(value as Map);
  }

  Future<Map<String, dynamic>> getBluetoothStatus() async =>
      Map<String, dynamic>.from(
          await _methodChannel.invokeMethod('getBluetoothStatus'));

  Future<String?> saveBackup(String json) async =>
      await _methodChannel.invokeMethod('saveBackup', json);

  Future<String?> readBackup() async =>
      await _methodChannel.invokeMethod('readBackup');

  Future<bool> launchIntentUri(String intentUri) async =>
      await _methodChannel.invokeMethod('launchIntentUri', intentUri);

  void addAppsChangedListener(void Function(Map<dynamic, dynamic>) listener) =>
      _eventChannel.receiveBroadcastStream().listen((event) => listener(event));
}
