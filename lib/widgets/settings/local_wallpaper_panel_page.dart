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

import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/tv_theme.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flauncher/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class LocalWallpaperPanelPage extends StatelessWidget {
  static const String routeName = "local_wallpaper_panel";

  static const List<String> _wallpapers = [
    "abstract",
    "animal",
    "architecture",
    "colorful",
    "landscape",
    "minimal",
    "plant",
    "space",
    "technology",
    "texture",
  ];

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text("Local", style: Theme.of(context).textTheme.titleLarge),
          Divider(),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: TvTokens.heroAspectRatio,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: _wallpapers.map((name) => EnsureVisible(alignment: 0.5, child: _wallpaperCard(name))).toList(),
            ),
          ),
        ],
      );

  Widget _wallpaperCard(String name) => Focus(
        key: Key("local-wallpaper-$name"),
        canRequestFocus: false,
        child: Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: _cardBorder(Focus.of(context).hasFocus),
                  child: InkWell(
                    autofocus: name == _wallpapers.first,
                    onTap: () => _setWallpaper(context, name),
                    child: Image.asset("assets/$name.png", fit: BoxFit.cover),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedDefaultTextStyle(
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        decoration: TextDecoration.underline,
                        color: Focus.of(context).hasFocus ? Colors.white : null,
                      ),
                  duration: TvTokens.focusDuration,
                  child: Text(name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _setWallpaper(BuildContext context, String name) async {
    final bytes = await rootBundle.load("assets/$name.png");
    await context.read<WallpaperService>().setLocalWallpaper(bytes.buffer.asUint8List());
  }

  ShapeBorder? _cardBorder(bool hasFocus) => hasFocus
      ? RoundedRectangleBorder(
          side: BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(Glass.radiusSmall),
        )
      : null;
}
