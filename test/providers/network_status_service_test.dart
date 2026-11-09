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

import 'package:flauncher/providers/network_status_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("refresh maps Wi-Fi status and local IP", () async {
    final channel = MockFLauncherChannel();
    when(channel.getNetworkStatus()).thenAnswer((_) async => {
          "hasInternet": true,
          "type": "wifi",
          "ipAddress": "192.168.1.20",
        });

    final service = NetworkStatusService(channel);
    await service.refresh();

    expect(service.status.connectionType, NetworkConnectionType.wifi);
    expect(service.status.hasInternet, isTrue);
    expect(service.status.ipAddress, "192.168.1.20");
    service.dispose();
  });

  test("refresh maps Ethernet without Internet", () async {
    final channel = MockFLauncherChannel();
    when(channel.getNetworkStatus()).thenAnswer((_) async => {
          "hasInternet": false,
          "type": "ethernet",
          "ipAddress": "192.168.1.30",
        });

    final service = NetworkStatusService(channel);
    await service.refresh();

    expect(service.status.connectionType, NetworkConnectionType.ethernet);
    expect(service.status.hasInternet, isFalse);
    expect(service.status.ipAddress, "192.168.1.30");
    service.dispose();
  });

  test("refresh reports no connection when channel fails", () async {
    final channel = MockFLauncherChannel();
    when(channel.getNetworkStatus()).thenThrow(Exception("not available"));

    final service = NetworkStatusService(channel);
    await service.refresh();

    expect(service.status.connectionType, NetworkConnectionType.none);
    expect(service.status.hasInternet, isFalse);
    expect(service.status.ipAddress, isNull);
    service.dispose();
  });

  test("refresh notifies listeners only when the status changes", () async {
    final channel = MockFLauncherChannel();
    when(channel.getNetworkStatus()).thenAnswer((_) async => {
          "hasInternet": true,
          "type": "wifi",
          "ipAddress": "192.168.1.20",
        });

    final service = NetworkStatusService(channel);
    await service.refresh();
    var notifications = 0;
    service.addListener(() => notifications++);

    await service.refresh();
    expect(notifications, 0);

    when(channel.getNetworkStatus()).thenAnswer((_) async => {
          "hasInternet": false,
          "type": "wifi",
          "ipAddress": "192.168.1.20",
        });
    await service.refresh();
    expect(notifications, 1);
    service.dispose();
  });
}
