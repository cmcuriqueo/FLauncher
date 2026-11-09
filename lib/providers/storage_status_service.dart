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

import 'package:flauncher/flauncher_channel.dart';
import 'package:flutter/widgets.dart';

const _gibibyte = 1024 * 1024 * 1024;

class StorageStatus {
  final int totalBytes;
  final int freeBytes;

  const StorageStatus({this.totalBytes = 0, this.freeBytes = 0});

  bool get known => totalBytes > 0;

  bool get low =>
      known && (freeBytes * 10 < totalBytes || freeBytes < _gibibyte);
}

String formatStorageBytes(int bytes) {
  if (bytes < 1024) return "$bytes B";
  const units = ["KB", "MB", "GB", "TB"];
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text =
      value >= 10 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return "$text ${units[unit]}";
}

class StorageStatusService extends ChangeNotifier with WidgetsBindingObserver {
  final FLauncherChannel _fLauncherChannel;

  Timer? _refreshTimer;
  bool _refreshing = false;
  bool _disposed = false;
  StorageStatus _status = StorageStatus();

  StorageStatus get status => _status;

  StorageStatusService(this._fLauncherChannel) {
    WidgetsBinding.instance.addObserver(this);
    refresh();
    _refreshTimer = Timer.periodic(Duration(seconds: 60), (_) => refresh());
  }

  Future<void> refresh() async {
    if (_refreshing || _disposed) return;
    _refreshing = true;
    final previousStatus = _status;
    try {
      final data = await _fLauncherChannel.getStorageStatus();
      _status = StorageStatus(
        totalBytes: _bytes(data["totalBytes"]),
        freeBytes: _bytes(data["freeBytes"]),
      );
    } catch (_) {
      _status = StorageStatus();
    }
    _refreshing = false;
    if (!_disposed &&
        (previousStatus.totalBytes != _status.totalBytes ||
            previousStatus.freeBytes != _status.freeBytes)) {
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  int _bytes(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
