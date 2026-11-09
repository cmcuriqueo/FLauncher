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

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/network_status_service.dart';
import 'package:flauncher/widgets/network_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets("shows connected state and local IP", (tester) async {
    await _pumpNetworkStatus(
        tester,
        _FakeNetworkChannel({
          "hasInternet": true,
          "type": "wifi",
          "ipAddress": "192.168.1.20",
        }));

    expect(find.text("Connected"), findsOneWidget);
    expect(find.text("IP 192.168.1.20"), findsOneWidget);
    expect(find.byIcon(Icons.wifi), findsOneWidget);
    await tester.pumpWidget(SizedBox());
  });

  testWidgets("distinguishes a connected network without Internet", (tester) async {
    await _pumpNetworkStatus(
        tester,
        _FakeNetworkChannel({
          "hasInternet": false,
          "type": "ethernet",
          "ipAddress": "192.168.1.30",
        }));

    expect(find.text("No Internet"), findsOneWidget);
    expect(find.text("IP 192.168.1.30"), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    await tester.pumpWidget(SizedBox());
  });

  testWidgets("shows no connection when the channel is unavailable", (tester) async {
    await _pumpNetworkStatus(tester, _FakeNetworkChannel(null));

    expect(find.text("No connection"), findsOneWidget);
    expect(find.textContaining("IP"), findsNothing);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    await tester.pumpWidget(SizedBox());
  });
}

Future<void> _pumpNetworkStatus(WidgetTester tester, FLauncherChannel channel) async {
  final service = NetworkStatusService(channel);
  await service.refresh();
  await tester.pumpWidget(
    ChangeNotifierProvider<NetworkStatusService>(
      create: (_) => service,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NetworkStatusWidget()),
      ),
    ),
  );
}

class _FakeNetworkChannel extends FLauncherChannel {
  final Map<String, dynamic>? _status;

  _FakeNetworkChannel(this._status);

  @override
  Future<Map<String, dynamic>> getNetworkStatus() async {
    final status = _status;
    if (status == null) throw Exception("not available");
    return status;
  }
}
