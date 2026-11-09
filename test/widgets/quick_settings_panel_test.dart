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
import 'package:flauncher/gradients.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/storage_status_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/widgets/quick_settings_panel.dart';
import 'package:flauncher/widgets/screensaver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../mocks.mocks.dart';

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  testWidgets("opens native Wi-Fi, Bluetooth and network settings",
      (tester) async {
    final channel = MockFLauncherChannel();
    when(channel.openWifiSettings()).thenAnswer((_) async => true);
    when(channel.openBluetoothSettings()).thenAnswer((_) async => true);
    when(channel.openNetworkSettings()).thenAnswer((_) async => true);
    final settings = await _settings();
    await _pumpPanel(tester, channel, settings);

    await tester.tap(find.text("Wi-Fi settings"));
    await tester.tap(find.text("Bluetooth settings"));
    await tester.tap(find.text("Android network settings"));

    verify(channel.openWifiSettings()).called(1);
    verify(channel.openBluetoothSettings()).called(1);
    verify(channel.openNetworkSettings()).called(1);
    settings.dispose();
  });

  testWidgets(
      "explains and opens accessibility setup when sleep is unavailable",
      (tester) async {
    final channel = MockFLauncherChannel();
    when(channel.lockScreen()).thenAnswer((_) async => false);
    final settings = await _settings();
    await _pumpPanel(tester, channel, settings);

    await tester.tap(find.text("Sleep"));
    await tester.pump();

    verify(channel.lockScreen()).called(1);
    expect(find.textContaining("enable FLauncher"), findsOneWidget);
    settings.dispose();
  });

  testWidgets("opens the configured screensaver and exits with any key",
      (tester) async {
    final channel = MockFLauncherChannel();
    final settings = await _settings();
    final wallpaper = MockWallpaperService();
    when(wallpaper.wallpaperBytes).thenReturn(null);
    when(wallpaper.gradient).thenReturn(FLauncherGradients.greatWhale);
    await _pumpPanel(tester, channel, settings,
        wallpaper: wallpaper, inDialog: true);

    await tester.tap(find.text("Screensaver"));
    await tester.pumpAndSettle();
    expect(find.byType(Screensaver), findsOneWidget);
    expect(find.text("Press any button to exit"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.byType(Screensaver), findsNothing);
    settings.dispose();
  });

  testWidgets("shows free storage and opens application management",
      (tester) async {
    final channel = MockFLauncherChannel();
    when(channel.getStorageStatus()).thenAnswer((_) async => {
          "totalBytes": 32 * 1024 * 1024 * 1024,
          "freeBytes": 512 * 1024 * 1024,
        });
    when(channel.openApplicationManagement()).thenAnswer((_) async => true);
    final settings = await _settings();
    await _pumpPanel(tester, channel, settings);

    expect(find.textContaining("Low storage"), findsOneWidget);
    await tester.tap(find.byKey(Key("storage-status")));
    await tester.pump();

    verify(channel.openApplicationManagement()).called(1);
    settings.dispose();
  });

  testWidgets("shows the launcher memory usage", (tester) async {
    final channel = MockFLauncherChannel();
    when(channel.getLauncherMemoryUsage())
        .thenAnswer((_) async => 128 * 1024 * 1024);
    final settings = await _settings();
    await _pumpPanel(tester, channel, settings);

    expect(find.text("Launcher memory"), findsOneWidget);
    expect(find.text("128 MB used"), findsOneWidget);
    settings.dispose();
  });
}

Future<SettingsService> _settings() async => SettingsService(
      await SharedPreferences.getInstance(),
      MockFirebaseCrashlytics(),
      MockFirebaseAnalytics(),
      MockFirebaseRemoteConfig(),
    );

Future<void> _pumpPanel(
  WidgetTester tester,
  FLauncherChannel channel,
  SettingsService settings, {
  WallpaperService? wallpaper,
  bool inDialog = false,
}) async {
  wallpaper ??= MockWallpaperService();
  if (wallpaper is MockWallpaperService) {
    when(wallpaper.wallpaperBytes).thenReturn(null);
    when(wallpaper.gradient).thenReturn(FLauncherGradients.greatWhale);
  }
  await tester.pumpWidget(MultiProvider(
    providers: [
      Provider<FLauncherChannel>.value(value: channel),
      ChangeNotifierProvider<SettingsService>.value(value: settings),
      ChangeNotifierProvider<WallpaperService>.value(value: wallpaper),
      ChangeNotifierProvider(create: (_) => StorageStatusService(channel)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: inDialog
            ? Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => QuickSettingsPanel(),
                    ),
                    child: Text("Open panel"),
                  );
                },
              )
            : Center(child: QuickSettingsPanel()),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  if (inDialog) {
    await tester.tap(find.text("Open panel"));
    await tester.pumpAndSettle();
  }
}
