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
import 'package:flauncher/providers/focused_app_service.dart';
import 'package:flauncher/tv_theme.dart';
import 'package:flauncher/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Panoramic section showing banner and metadata of the app currently focused
/// in the rows below. Purely presentational: it never takes focus or input.
class ContextualHero extends StatelessWidget {
  static const double height = 200;

  const ContextualHero({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Selector<FocusedAppService, App?>(
        selector: (_, service) => service.focusedApp,
        builder: (context, focusedApp, _) => IgnorePointer(
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: AnimatedSwitcher(
              duration: TvTokens.focusDuration,
              child: focusedApp == null ? SizedBox.shrink() : _heroContent(context, focusedApp),
            ),
          ),
        ),
      );

  Widget _heroContent(BuildContext context, App app) => ClipRRect(
        key: ValueKey(app.packageName),
        borderRadius: TvTokens.cardBorderRadius,
        child: Container(
          decoration: BoxDecoration(
            color: Glass.fill(0.10),
            borderRadius: TvTokens.cardBorderRadius,
            border: Border.all(color: Glass.stroke(0.12)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (app.banner != null)
                Image.memory(app.banner!, fit: BoxFit.cover)
              else if (app.icon != null)
                Center(
                  child: Image.memory(app.icon!, width: TvTokens.favoriteIconSize, height: TvTokens.favoriteIconSize),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                  ),
                ),
              ),
              Positioned(
                left: 24,
                bottom: 20,
                right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      app.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(color: TvTokens.textPrimary, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "v${app.version}",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: TvTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
