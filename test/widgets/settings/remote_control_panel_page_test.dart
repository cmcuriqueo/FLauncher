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

import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/remote_control.dart';
import 'package:flauncher/widgets/settings/remote_control_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../../mocks.dart';
import '../../mocks.mocks.dart';

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  testWidgets("captures a button for the Netflix preset", (tester) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final settingsService = SettingsService(
      sharedPreferences,
      MockFirebaseCrashlytics(),
      MockFirebaseAnalytics(),
      MockFirebaseRemoteConfig(),
    );
    final appsService = MockAppsService();
    when(appsService.applications).thenReturn([
      fakeApp(packageName: netflixPackageName, name: "Netflix"),
      fakeApp(packageName: youtubePackageName, name: "YouTube"),
    ]);
    await _pumpPage(tester, settingsService, appsService);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text("Press a button for Netflix"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlayPause,
        platform: "android");
    await tester.pump();

    expect(settingsService.remoteShortcuts, {85: netflixPackageName});
    expect(find.text("Button 85"), findsOneWidget);
    settingsService.dispose();
  });

  testWidgets("removes an existing assignment", (tester) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final settingsService = SettingsService(
      sharedPreferences,
      MockFirebaseCrashlytics(),
      MockFirebaseAnalytics(),
      MockFirebaseRemoteConfig(),
    );
    final appsService = MockAppsService();
    when(appsService.applications).thenReturn(
        [fakeApp(packageName: netflixPackageName, name: "Netflix")]);
    await settingsService.setRemoteShortcut(85, netflixPackageName);
    await _pumpPage(tester, settingsService, appsService);

    await tester
        .tap(find.byKey(Key("remove-remote-shortcut-$netflixPackageName")));
    await tester.pump();

    expect(settingsService.remoteShortcuts, isEmpty);
    expect(find.text("Button 85"), findsNothing);
    settingsService.dispose();
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  SettingsService settingsService,
  AppsService appsService,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider<AppsService>.value(value: appsService),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(child: RemoteControlPanelPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
