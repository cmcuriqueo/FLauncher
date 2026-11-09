/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/top_bar_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../../mocks.mocks.dart';

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  testWidgets("persists all top-bar visibility preferences", (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final settings = SettingsService(
      preferences,
      MockFirebaseCrashlytics(),
      MockFirebaseAnalytics(),
      MockFirebaseRemoteConfig(),
    );
    await tester.pumpWidget(ChangeNotifierProvider<SettingsService>.value(
      value: settings,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: TopBarPanelPage()),
      ),
    ));

    expect(settings.showDate, isTrue);
    expect(settings.showNetworkStatus, isTrue);
    expect(settings.showLocalIpAddress, isTrue);

    await tester.tap(find.byKey(Key("show-date-setting")));
    await tester.tap(find.byKey(Key("show-network-setting")));
    await tester.tap(find.byKey(Key("show-ip-setting")));
    await tester.pump();

    expect(settings.showDate, isFalse);
    expect(settings.showNetworkStatus, isFalse);
    expect(settings.showLocalIpAddress, isFalse);
    expect(preferences.getBool("show_date"), isFalse);
    expect(preferences.getBool("show_network_status"), isFalse);
    expect(preferences.getBool("show_local_ip_address"), isFalse);
    settings.dispose();
  });
}
