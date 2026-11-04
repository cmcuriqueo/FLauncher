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

import 'package:flauncher/database.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/focused_app_service.dart';
import 'package:flauncher/tv_theme.dart';
import 'package:flauncher/widgets/application_info_panel.dart';
import 'package:flauncher/widgets/focus_keyboard_listener.dart';
import 'package:flauncher/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class FavoriteAppCard extends StatelessWidget {
  final App application;
  final bool autofocus;

  FavoriteAppCard({Key? key, required this.application, this.autofocus = false}) : super(key: key);

  @override
  Widget build(BuildContext context) => FocusKeyboardListener(
        onPressed: (key) => _onPressed(context, key),
        onLongPress: (key) => _onLongPress(context, key),
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          if (focused) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.read<FocusedAppService>().setFocusedApp(application);
              }
            });
          }
          return SizedBox(
            width: TvTokens.favoriteIconSize,
            height: TvTokens.favoriteIconSize,
            child: AnimatedContainer(
              duration: TvTokens.focusDuration,
              curve: TvTokens.focusCurve,
              transformAlignment: Alignment.center,
              transform: TvTokens.focusTransform(focused),
              decoration: BoxDecoration(
                borderRadius: TvTokens.cardBorderRadius,
                boxShadow: focused ? TvTokens.focusShadow : TvTokens.restShadow,
              ),
              child: Material(
                color: Glass.fill(0.10),
                borderRadius: TvTokens.cardBorderRadius,
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    InkWell(
                      autofocus: autofocus,
                      focusColor: Colors.transparent,
                      onTap: () => _onPressed(context, null),
                      onLongPress: () => _onLongPress(context, null),
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Ink.image(image: MemoryImage(application.icon!)),
                      ),
                    ),
                    _ring(focused),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Widget _ring(bool focused) => IgnorePointer(
        child: AnimatedContainer(
          duration: TvTokens.focusDuration,
          curve: TvTokens.focusCurve,
          decoration: BoxDecoration(
            borderRadius: TvTokens.cardBorderRadius,
            border: Border.all(
              color: focused ? Colors.white.withOpacity(0.95) : Glass.stroke(0.12),
              width: focused ? TvTokens.focusStrokeWidth : 1,
            ),
          ),
        ),
      );

  KeyEventResult _onPressed(BuildContext context, LogicalKeyboardKey? key) {
    if (key == null || longPressableKeys.contains(key)) {
      context.read<AppsService>().launchApp(application);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onLongPress(BuildContext context, LogicalKeyboardKey? key) {
    if (key == null || longPressableKeys.contains(key)) {
      showDialog(
        context: context,
        builder: (context) => ApplicationInfoPanel(category: null, application: application),
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
