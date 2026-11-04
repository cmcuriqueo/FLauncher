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

import 'dart:typed_data';
import 'dart:ui';

import 'package:flauncher/custom_traversal_policy.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/tv_theme.dart';
import 'package:flauncher/widgets/apps_grid.dart';
import 'package:flauncher/widgets/category_row.dart';
import 'package:flauncher/widgets/contextual_hero.dart';
import 'package:flauncher/widgets/favorites_row.dart';
import 'package:flauncher/widgets/glass.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/time_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class FLauncher extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
        policy: RowByRowTraversalPolicy(),
        child: Stack(
          children: [
            Consumer<WallpaperService>(
              builder: (_, wallpaper, __) => _wallpaper(context, wallpaper.wallpaperBytes, wallpaper.gradient.gradient),
            ),
            _scrim(),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: _appBar(context),
              body: Padding(
                padding: EdgeInsets.fromLTRB(TvTokens.overscanHorizontal, 8, TvTokens.overscanHorizontal, 0),
                child: Consumer<AppsService>(
                  builder: (context, appsService, _) => appsService.initialized
                      ? SingleChildScrollView(child: _content(appsService))
                      : _emptyState(context),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _content(AppsService appsService) {
    final favorites = appsService.favoriteApplications;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: ContextualHero(key: Key("contextual-hero")),
        ),
        if (favorites.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: FavoritesRow(key: Key("favorites"), applications: favorites),
          ),
        ..._categoryWidgets(appsService.categoriesWithApps),
      ],
    );
  }

  List<Widget> _categoryWidgets(List<CategoryWithApps> categoriesWithApps) =>
      categoriesWithApps.map((categoryWithApps) {
        switch (categoryWithApps.category.type) {
          case CategoryType.row:
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CategoryRow(
                  key: Key(categoryWithApps.category.id.toString()),
                  category: categoryWithApps.category,
                  applications: categoryWithApps.applications),
            );
          case CategoryType.grid:
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: AppsGrid(
                  key: Key(categoryWithApps.category.id.toString()),
                  category: categoryWithApps.category,
                  applications: categoryWithApps.applications),
            );
        }
      }).toList();

  AppBar _appBar(BuildContext context) => AppBar(
        toolbarHeight: 72,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 24),
            child: Center(
              child: GlassContainer(
                radius: 999,
                padding: EdgeInsets.fromLTRB(16, 4, 6, 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TimeWidget(),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Container(width: 1, height: 18, color: Glass.stroke(0.25)),
                    ),
                    IconButton(
                      padding: EdgeInsets.all(6),
                      constraints: BoxConstraints(),
                      splashRadius: 18,
                      icon: Icon(Icons.settings_outlined),
                      onPressed: () => showDialog(context: context, builder: (_) => SettingsPanel()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _scrim() => Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.30),
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.40),
                ],
                stops: [0, 0.4, 1],
              ),
            ),
          ),
        ),
      );

  Widget _wallpaper(BuildContext context, Uint8List? wallpaperImage, Gradient gradient) => wallpaperImage != null
      ? Image.memory(
          wallpaperImage,
          key: Key("background"),
          fit: BoxFit.cover,
          height: window.physicalSize.height,
          width: window.physicalSize.width,
        )
      : Container(key: Key("background"), decoration: BoxDecoration(gradient: gradient));

  Widget _emptyState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.loading, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      );
}
