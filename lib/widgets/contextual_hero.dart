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
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/tv_theme.dart';
import 'package:flauncher/widgets/focus_keyboard_listener.dart';
import 'package:flauncher/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Panoramic section at the top of the home screen. Shows, by priority:
/// 1. The "continue watching" item from the Android TV Watch Next channel
///    when the hero itself is focused or nothing else is focused.
/// 2. The app currently focused in the rows below.
/// 3. The most recently launched app, as a suggestion.
/// The hero takes focus only when it has actionable content; pressing select
/// resumes the content or launches the suggested app.
class ContextualHero extends StatefulWidget {
  static const double height = 200;

  const ContextualHero({Key? key}) : super(key: key);

  @override
  State<ContextualHero> createState() => _ContextualHeroState();
}

class _ContextualHeroState extends State<ContextualHero> {
  @override
  Widget build(BuildContext context) {
    final watchNextItem = context.select<WatchNextService, WatchNextItem?>((service) => service.firstItem);
    final focusedApp = context.select<FocusedAppService, App?>((service) => service.focusedApp);
    final recentApp = _mostRecentApp(context);

    return FocusKeyboardListener(
      onPressed: (key) => _onPressed(context, key, watchNextItem, focusedApp, recentApp),
      builder: (context) {
        final heroFocused = Focus.of(context).hasFocus;
        final Widget? content;
        final Key contentKey;
        if (watchNextItem != null && (heroFocused || focusedApp == null)) {
          contentKey = Key("watch-next-${watchNextItem.title}");
          content = _watchNextContent(context, watchNextItem);
        } else if (focusedApp != null) {
          contentKey = Key("app-${focusedApp.packageName}");
          content = _appContent(context, focusedApp);
        } else if (recentApp != null) {
          contentKey = Key("recent-${recentApp.packageName}");
          content = _recentContent(context, recentApp);
        } else {
          contentKey = Key("empty");
          content = null;
        }

        if (content == null) {
          return SizedBox.shrink();
        }
        return SizedBox(
          height: ContextualHero.height,
          width: double.infinity,
          child: AnimatedSwitcher(
            duration: TvTokens.focusDuration,
            child: Material(
              key: contentKey,
              type: MaterialType.transparency,
              child: InkWell(
                focusColor: Colors.transparent,
                onTap: () => _onPressed(context, null, watchNextItem, focusedApp, recentApp),
                child: _heroFrame(content, heroFocused),
              ),
            ),
          ),
        );
      },
    );
  }

  App? _mostRecentApp(BuildContext context) {
    final recentPackages = context.select<SettingsService, List<String>>((service) => service.recentPackages);
    if (recentPackages.isEmpty) return null;
    final apps = context.watch<AppsService>().applications;
    for (final packageName in recentPackages) {
      for (final app in apps) {
        if (app.packageName == packageName) return app;
      }
    }
    return null;
  }

  Widget _heroFrame(Widget child, bool focused) => AnimatedContainer(
        duration: TvTokens.focusDuration,
        curve: TvTokens.focusCurve,
        decoration: BoxDecoration(
          borderRadius: TvTokens.cardBorderRadius,
          boxShadow: focused ? TvTokens.focusShadow : Glass.restShadow,
          border: Border.all(
            color: focused ? Colors.white.withOpacity(0.95) : Glass.stroke(0.12),
            width: focused ? TvTokens.focusStrokeWidth : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: TvTokens.cardBorderRadius,
          child: Container(
            color: Glass.fill(0.10),
            child: Stack(
              fit: StackFit.expand,
              children: [child, SpecularHighlight(borderRadius: TvTokens.cardBorderRadius, opacity: 0.7)],
            ),
          ),
        ),
      );

  Widget _watchNextContent(BuildContext context, WatchNextItem item) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (item.poster != null) Image.memory(item.poster!, fit: BoxFit.cover),
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
              _chip(context, l10n.continueWatching),
              SizedBox(height: 8),
              Text(
                item.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(color: TvTokens.textPrimary, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.progress != null) ...[
                SizedBox(height: 8),
                SizedBox(
                  width: 240,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      minHeight: 4,
                      backgroundColor: Glass.fill(0.25),
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _appContent(BuildContext context, App app) => Stack(
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
      );

  Widget _recentContent(BuildContext context, App app) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (app.banner != null) Opacity(opacity: 0.4, child: Image.memory(app.banner!, fit: BoxFit.cover)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.black.withOpacity(0.75), Colors.black.withOpacity(0.3)],
            ),
          ),
        ),
        Positioned(
          left: 24,
          bottom: 20,
          right: 24,
          child: Row(
            children: [
              if (app.icon != null) Image.memory(app.icon!, width: 56, height: 56),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _chip(context, l10n.recent),
                    SizedBox(height: 8),
                    Text(
                      app.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(color: TvTokens.textPrimary, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, String label) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Glass.fill(0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Glass.stroke(0.25)),
        ),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
        ),
      );

  KeyEventResult _onPressed(
      BuildContext context, LogicalKeyboardKey? key, WatchNextItem? watchNextItem, App? focusedApp, App? recentApp) {
    if (key != null && key != LogicalKeyboardKey.select && key != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    final heroFocused = Focus.of(context).hasFocus;
    if (watchNextItem != null && (heroFocused || focusedApp == null)) {
      context.read<WatchNextService>().launchItem(watchNextItem);
      return KeyEventResult.handled;
    }
    if (heroFocused && focusedApp != null) {
      context.read<AppsService>().launchApp(focusedApp);
      return KeyEventResult.handled;
    }
    if (focusedApp == null && recentApp != null) {
      context.read<AppsService>().launchApp(recentApp);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
