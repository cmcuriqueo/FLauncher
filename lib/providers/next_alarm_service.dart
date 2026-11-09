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

class NextAlarmService extends ChangeNotifier with WidgetsBindingObserver {
  final FLauncherChannel _channel;
  Timer? _timer;
  bool _disposed = false;
  DateTime? _nextAlarm;

  DateTime? get nextAlarm => _nextAlarm;

  NextAlarmService(this._channel) {
    WidgetsBinding.instance.addObserver(this);
    refresh();
    _timer = Timer.periodic(Duration(seconds: 30), (_) => refresh());
  }

  Future<void> refresh() async {
    final previousAlarm = _nextAlarm;
    try {
      final millis = await _channel.getNextAlarm();
      _nextAlarm =
          millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      _nextAlarm = null;
    }
    if (!_disposed && previousAlarm != _nextAlarm) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
