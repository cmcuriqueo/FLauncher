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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'mocks.dart';
import 'mocks.mocks.dart';

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  test("accepts Android buttons and protects navigation keys", () {
    final mediaButton =
        RawKeyDownEvent(data: RawKeyEventDataAndroid(keyCode: 175));
    final arrow = RawKeyDownEvent(data: RawKeyEventDataAndroid(keyCode: 22));

    expect(remoteShortcutKeyCode(mediaButton), 175);
    expect(remoteShortcutKeyCode(arrow), isNull);
  });

  testWidgets("a mapped button launches its application", (tester) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final settingsService = SettingsService(
      sharedPreferences,
      MockFirebaseCrashlytics(),
      MockFirebaseAnalytics(),
      MockFirebaseRemoteConfig(),
    );
    final appsService = MockAppsService();
    final netflix = fakeApp(packageName: netflixPackageName, name: "Netflix");
    when(appsService.applications).thenReturn([netflix]);
    await settingsService.setRemoteShortcut(85, netflixPackageName);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: settingsService),
          ChangeNotifierProvider<AppsService>.value(value: appsService),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Focus(
              autofocus: true,
              onKey: (_, event) => handleRemoteShortcut(context, event),
              child: SizedBox(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlayPause,
        platform: "android");

    verify(appsService.launchApp(netflix)).called(1);
    settingsService.dispose();
  });
}
