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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

const netflixPackageName = "com.netflix.ninja";
const youtubePackageName = "com.google.android.youtube.tv";

final _protectedKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.select,
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.gameButtonA,
  LogicalKeyboardKey.gameButtonB,
  LogicalKeyboardKey.escape,
  LogicalKeyboardKey.goBack,
  LogicalKeyboardKey.goHome,
  LogicalKeyboardKey.home,
};

int? remoteShortcutKeyCode(RawKeyEvent event) {
  if (event is! RawKeyDownEvent ||
      event.data is! RawKeyEventDataAndroid ||
      _protectedKeys.contains(event.logicalKey)) {
    return null;
  }
  return (event.data as RawKeyEventDataAndroid).keyCode;
}

KeyEventResult handleRemoteShortcut(BuildContext context, RawKeyEvent event) {
  final keyCode = remoteShortcutKeyCode(event);
  if (keyCode == null) return KeyEventResult.ignored;

  final packageName = context.read<SettingsService>().remoteShortcuts[keyCode];
  if (packageName == null) return KeyEventResult.ignored;

  final appsService = context.read<AppsService>();
  for (final app in appsService.applications) {
    if (app.packageName == packageName) {
      appsService.launchApp(app);
      return KeyEventResult.handled;
    }
  }
  return KeyEventResult.ignored;
}
