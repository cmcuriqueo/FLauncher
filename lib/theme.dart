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

import 'package:flauncher/widgets/glass.dart';
import 'package:flutter/material.dart';

ThemeData fLauncherTheme() {
  final typography = Typography.material2018();
  final base = typography.white;
  final textTheme = base.copyWith(
    headlineMedium: base.headlineMedium!.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.5),
    titleLarge: base.titleLarge!.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.3),
    titleMedium: base.titleMedium!.copyWith(fontWeight: FontWeight.w500, letterSpacing: -0.2),
    bodyMedium: base.bodyMedium!.copyWith(letterSpacing: -0.1),
    bodySmall: base.bodySmall!.copyWith(color: Colors.white.withOpacity(0.7)),
  );
  final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Glass.radiusSmall));

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Glass.accent,
      secondary: Glass.accent,
      surface: Glass.surface,
      background: Glass.scaffold,
      error: Glass.red,
    ),
    typography: typography,
    textTheme: textTheme,
    primaryColor: Glass.accent,
    scaffoldBackgroundColor: Glass.scaffold,
    canvasColor: Glass.surface,
    cardColor: Glass.fill(0.08),
    dialogBackgroundColor: Glass.surface.withOpacity(0.92),
    dividerColor: Glass.stroke(0.12),
    focusColor: Glass.fill(0.18),
    hoverColor: Glass.fill(0.08),
    highlightColor: Glass.fill(0.10),
    splashColor: Glass.fill(0.12),
    iconTheme: IconThemeData(color: Colors.white),
    appBarTheme: AppBarTheme(elevation: 0, backgroundColor: Colors.transparent),
    cardTheme: CardTheme(elevation: 0, shape: rounded, margin: EdgeInsets.symmetric(vertical: 4)),
    dialogTheme: DialogTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Glass.radiusLarge),
        side: BorderSide(color: Glass.stroke(0.14)),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    dividerTheme: DividerThemeData(thickness: 0.5, space: 16),
    listTileTheme: ListTileThemeData(shape: rounded),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.white),
        shape: MaterialStateProperty.all(rounded),
        alignment: Alignment.centerLeft,
        padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
        minimumSize: MaterialStateProperty.all(Size(48, 44)),
        overlayColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.pressed)) return Glass.fill(0.24);
          if (states.contains(MaterialState.focused)) return Glass.fill(0.16);
          if (states.contains(MaterialState.hovered)) return Glass.fill(0.08);
          return null;
        }),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        foregroundColor: Colors.white,
        shape: rounded,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.all(Colors.white),
      trackColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected) ? Glass.green : Glass.fill(0.25),
      ),
    ),
    tabBarTheme: TabBarTheme(
      indicator: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Glass.fill(0.16)),
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withOpacity(0.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Glass.fill(0.08),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Glass.radiusSmall), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Glass.radiusSmall),
        borderSide: BorderSide(color: Glass.stroke(0.6)),
      ),
      labelStyle: textTheme.bodyMedium!.copyWith(color: Colors.white.withOpacity(0.7)),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Colors.white,
      selectionColor: Glass.accent.withOpacity(0.4),
      selectionHandleColor: Glass.accent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Glass.surface.withOpacity(0.95),
      contentTextStyle: textTheme.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Glass.radiusMedium),
        side: BorderSide(color: Glass.stroke(0.14)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: Colors.white),
  );
}
