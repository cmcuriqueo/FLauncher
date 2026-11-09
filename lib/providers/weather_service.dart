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
import 'dart:io';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flutter/widgets.dart';

class WeatherReport {
  final double temperature;
  final int code;

  WeatherReport({required this.temperature, required this.code});
}

class WeatherService extends ChangeNotifier with WidgetsBindingObserver {
  final FLauncherChannel _channel;
  Timer? _timer;
  bool _disposed = false;
  bool _refreshing = false;
  WeatherReport? _report;

  WeatherReport? get report => _report;

  WeatherService(this._channel) {
    WidgetsBinding.instance.addObserver(this);
    refresh();
    _timer = Timer.periodic(Duration(minutes: 30), (_) => refresh());
  }

  Future<void> refresh() async {
    if (_refreshing || _disposed) return;
    _refreshing = true;
    try {
      final location = await _channel.getLastLocation();
      if (location == null) {
        _report = null;
      } else {
        _report = await _fetch(
          (location["latitude"] as num).toDouble(),
          (location["longitude"] as num).toDouble(),
        );
      }
    } catch (_) {
      _report = null;
    }
    _refreshing = false;
    if (!_disposed) notifyListeners();
  }

  Future<WeatherReport?> _fetch(double latitude, double longitude) async {
    final client = HttpClient();
    try {
      final uri = Uri.https("api.open-meteo.com", "/v1/forecast", {
        "latitude": latitude.toString(),
        "longitude": longitude.toString(),
        "current_weather": "true",
      });
      final request = await client.getUrl(uri).timeout(Duration(seconds: 8));
      final response =
          await request.close().timeout(Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      final current = jsonDecode(body)["current_weather"];
      if (current is! Map) return null;
      return WeatherReport(
        temperature: (current["temperature"] as num).toDouble(),
        code: current["weathercode"] as int? ?? 0,
      );
    } finally {
      client.close(force: true);
    }
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
