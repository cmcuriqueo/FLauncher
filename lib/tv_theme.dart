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

import 'package:flutter/material.dart';

/// Design tokens for the TV interface (dark mode, Leanback-style spatial
/// navigation). Every interactive component must read its colors, geometry
/// and motion values from here so the focus behavior stays consistent.
abstract class TvTokens {
  // Palette
  static const Color bgDark = Color(0xFF0F1216);
  static const Color bgCardDefault = Color(0xFF1A1E24);
  static const Color bgCardFocus = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFF1F3F5);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textFocus = Color(0xFF000000);
  static const Color focusStroke = Color(0xFF3D82F6);

  // Geometry
  static const double radiusCard = 12;
  static const double focusScale = 1.10;
  static const double focusStrokeWidth = 2.5;
  static const double overscanHorizontal = 48;
  static const double overscanVertical = 27;
  static const double favoriteIconSize = 80;
  static const double heroAspectRatio = 16 / 9;

  // Motion: immediate but smooth focus transitions, 150-200ms, decelerated.
  static const Duration focusDuration = Duration(milliseconds: 180);
  static const Curve focusCurve = Curves.decelerate;

  static BorderRadius get cardBorderRadius => BorderRadius.circular(radiusCard);

  /// Scale transform applied on focus. Runs at the paint layer only: it must
  /// never trigger a relayout of the card subtree.
  static Matrix4 focusTransform(bool focused) {
    final scale = focused ? focusScale : 1.0;
    return Matrix4.diagonal3Values(scale, scale, 1.0);
  }

  /// Surface decoration for the two card states. The focused state adds the
  /// accent stroke and an elevated shadow to stand out from the background.
  static BoxDecoration cardDecoration(bool focused) => BoxDecoration(
        color: focused ? bgCardFocus : bgCardDefault,
        borderRadius: cardBorderRadius,
        border: Border.all(
          color: focused ? focusStroke : Colors.white.withOpacity(0.08),
          width: focused ? focusStrokeWidth : 1,
        ),
        boxShadow: focused ? focusShadow : restShadow,
      );

  static final List<BoxShadow> restShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static final List<BoxShadow> focusShadow = [
    BoxShadow(color: focusStroke.withOpacity(0.35), blurRadius: 24, spreadRadius: 1),
    BoxShadow(color: Colors.black.withOpacity(0.50), blurRadius: 20, offset: Offset(0, 10)),
  ];

  /// Safe padding for primary views, avoiding overscan cropping on
  /// physical TV screens.
  static const EdgeInsets overscanPadding =
      EdgeInsets.symmetric(horizontal: overscanHorizontal, vertical: overscanVertical);

  static TextStyle cardTextStyle(BuildContext context, bool focused) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: focused ? textFocus : textPrimary,
            fontWeight: focused ? FontWeight.w600 : FontWeight.w500,
          );
}
