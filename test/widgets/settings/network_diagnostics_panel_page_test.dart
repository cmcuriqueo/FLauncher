/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/network_diagnostics_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/network_diagnostics_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../mocks.mocks.dart';
import 'network_diagnostics_test_transport.dart';

void main() {
  testWidgets("runs a test and displays network results", (tester) async {
    final channel = MockFLauncherChannel();
    when(channel.openNetworkSettings()).thenAnswer((_) async => true);
    when(channel.getNetworkDetails()).thenAnswer((_) async => {
          "gateway": "192.168.1.1",
          "dnsServers": ["1.1.1.1"],
          "vpnActive": false,
          "wifiSignal": -55,
          "wifiFrequency": 5180,
          "wifiLinkSpeed": 866,
        });
    final service =
        NetworkDiagnosticsService(channel, FakeNetworkDiagnosticsTransport());
    final settings = MockSettingsService();
    when(settings.lastNetworkDiagnostics).thenReturn(null);
    when(settings.setLastNetworkDiagnostics(
            argThat(isA<NetworkDiagnosticsResult>())))
        .thenAnswer((_) async {});

    await _pumpPage(tester, channel, settings, service);
    await service.refreshDetails();
    await tester.pump();
    expect(find.text("192.168.1.1"), findsOneWidget);
    expect(find.text("1.1.1.1"), findsOneWidget);
    expect(find.text("-55 dBm"), findsOneWidget);

    await tester.tap(find.byKey(Key("start-network-test")));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text("80.0 Mbps"), findsOneWidget);
    expect(find.text("10.0 Mbps"), findsOneWidget);
    expect(find.text("10 / 15 / 20 ms"), findsOneWidget);
    expect(find.text("0%"), findsOneWidget);
    expect(find.text("Stable"), findsOneWidget);
    verify(settings.setLastNetworkDiagnostics(
            argThat(isA<NetworkDiagnosticsResult>())))
        .called(1);

    await tester.tap(find.text("Android network settings"));
    verify(channel.openNetworkSettings()).called(1);
    service.dispose();
  });

  testWidgets("shows unavailable details without blocking the test action",
      (tester) async {
    final channel = MockFLauncherChannel();
    final settings = MockSettingsService();
    when(settings.lastNetworkDiagnostics).thenReturn(null);
    final service =
        NetworkDiagnosticsService(channel, FakeNetworkDiagnosticsTransport());
    await _pumpPage(tester, channel, settings, service);
    await service.refreshDetails();
    await tester.pump();

    expect(find.text("Not available"), findsNWidgets(5));
    expect(find.byKey(Key("start-network-test")), findsOneWidget);
    service.dispose();
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  FLauncherChannel channel,
  SettingsService settings,
  NetworkDiagnosticsService service,
) async {
  await tester.pumpWidget(MultiProvider(
    providers: [
      Provider<FLauncherChannel>.value(value: channel),
      ChangeNotifierProvider<SettingsService>.value(value: settings),
      ChangeNotifierProvider<NetworkDiagnosticsService>.value(value: service),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: NetworkDiagnosticsPanelPage()),
    ),
  ));
  await tester.pumpAndSettle();
}
