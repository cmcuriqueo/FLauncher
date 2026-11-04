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
import 'package:flauncher/tv_theme.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flauncher/widgets/favorite_app_card.dart';
import 'package:flauncher/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FavoritesRow extends StatelessWidget {
  final List<App> applications;

  FavoritesRow({Key? key, required this.applications}) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Text(AppLocalizations.of(context)!.favorites, style: Glass.sectionTitle(context)),
          ),
          SizedBox(
            height: TvTokens.favoriteIconSize + 24,
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              scrollDirection: Axis.horizontal,
              itemCount: applications.length,
              itemBuilder: (context, index) => EnsureVisible(
                key: Key("favorite-${applications[index].packageName}"),
                alignment: 0.1,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: FavoriteAppCard(
                    application: applications[index],
                    autofocus: index == 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
