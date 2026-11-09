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

enum NetworkConnectionType { unknown, none, wifi, ethernet, other }

class NetworkStatus {
  final NetworkConnectionType connectionType;
  final bool hasInternet;
  final String? ipAddress;

  const NetworkStatus({
    this.connectionType = NetworkConnectionType.unknown,
    this.hasInternet = false,
    this.ipAddress,
  });
}

class NetworkStatusService extends ChangeNotifier with WidgetsBindingObserver {
  final FLauncherChannel _fLauncherChannel;

  Timer? _refreshTimer;
  bool _refreshing = false;
  bool _disposed = false;
  NetworkStatus _status = NetworkStatus();

  NetworkStatus get status => _status;

  NetworkStatusService(this._fLauncherChannel) {
    WidgetsBinding.instance.addObserver(this);
    refresh();
    _refreshTimer = Timer.periodic(Duration(seconds: 15), (_) => refresh());
  }

  Future<void> refresh() async {
    if (_refreshing || _disposed) return;
    _refreshing = true;
    final previousStatus = _status;
    try {
      final data = await _fLauncherChannel.getNetworkStatus();
      _status = NetworkStatus(
        connectionType: _connectionType(data["type"] as String?),
        hasInternet: data["hasInternet"] as bool? ?? false,
        ipAddress: data["ipAddress"] as String?,
      );
    } catch (_) {
      _status = NetworkStatus(connectionType: NetworkConnectionType.none);
    }
    _refreshing = false;
    if (!_disposed &&
        (previousStatus.connectionType != _status.connectionType ||
            previousStatus.hasInternet != _status.hasInternet ||
            previousStatus.ipAddress != _status.ipAddress)) {
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

  NetworkConnectionType _connectionType(String? type) {
    switch (type) {
      case "wifi":
        return NetworkConnectionType.wifi;
      case "ethernet":
        return NetworkConnectionType.ethernet;
      case "other":
        return NetworkConnectionType.other;
      case "none":
        return NetworkConnectionType.none;
      default:
        return NetworkConnectionType.unknown;
    }
  }
}
