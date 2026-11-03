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

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flauncher/actions.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/ticker_model.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/unsplash_service.dart';
import 'package:flauncher/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'database.dart';
import 'flauncher.dart';
import 'flauncher_channel.dart';

class FLauncherApp extends StatelessWidget {
  final SharedPreferences _sharedPreferences;
  final FirebaseCrashlytics _firebaseCrashlytics;
  final FirebaseAnalytics _firebaseAnalytics;
  final ImagePicker _imagePicker;
  final FLauncherChannel _fLauncherChannel;
  final FLauncherDatabase _fLauncherDatabase;
  final UnsplashService _unsplashService;
  final FirebaseRemoteConfig _firebaseRemoteConfig;

  FLauncherApp(
    this._sharedPreferences,
    this._firebaseCrashlytics,
    this._firebaseAnalytics,
    this._imagePicker,
    this._fLauncherChannel,
    this._fLauncherDatabase,
    this._unsplashService,
    this._firebaseRemoteConfig,
  );

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) =>
                  SettingsService(_sharedPreferences, _firebaseCrashlytics, _firebaseAnalytics, _firebaseRemoteConfig),
              lazy: false),
          ChangeNotifierProvider(create: (_) => AppsService(_fLauncherChannel, _fLauncherDatabase)),
          ChangeNotifierProxyProvider<SettingsService, WallpaperService>(
              create: (_) => WallpaperService(_imagePicker, _fLauncherChannel, _unsplashService),
              update: (_, settingsService, wallpaperService) => wallpaperService!..settingsService = settingsService),
          Provider<TickerModel>(create: (context) => TickerModel(null))
        ],
        child: Consumer<SettingsService>(
          builder: (context, settingsService, _) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: settingsService.languageCode != null ? Locale(settingsService.languageCode!) : null,
          shortcuts: {
            ...WidgetsApp.defaultShortcuts,
            SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.gameButtonB): PrioritizedIntents(orderedIntents: [
              DismissIntent(),
              BackIntent(),
            ]),
          },
          actions: {
            ...WidgetsApp.defaultActions,
            DirectionalFocusIntent: SoundFeedbackDirectionalFocusAction(context),
          },
          title: 'FLauncher',
          theme: fLauncherTheme(),
          home: Builder(
            builder: (context) => WillPopScope(
              onWillPop: () async {
                final shouldPop = await shouldPopScope(context);
                if (!shouldPop) {
                  context.read<AppsService>().startAmbientMode();
                }
                return shouldPop;
              },
              child: Actions(actions: {BackIntent: BackAction(context, systemNavigator: true)}, child: FLauncher()),
            ),
          ),
          ),
        ),
      );
}
