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
import 'package:flauncher/wallpaper_repo_service.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flauncher/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class RepoWallpaperPanelPage extends StatefulWidget {
  static const String routeName = "repo_wallpaper_panel";

  final WallpaperRepoService repoService;

  RepoWallpaperPanelPage({Key? key, WallpaperRepoService? repoService})
      : repoService = repoService ?? WallpaperRepoService(),
        super(key: key);

  @override
  State<RepoWallpaperPanelPage> createState() => _RepoWallpaperPanelPageState();
}

class _RepoWallpaperPanelPageState extends State<RepoWallpaperPanelPage> {
  late final Future<List<RepoWallpaper>> _wallpapers = widget.repoService.fetchWallpapers();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(AppLocalizations.of(context)!.wallpaperRepo, style: Theme.of(context).textTheme.titleLarge),
          Divider(),
          Expanded(
            child: FutureBuilder<List<RepoWallpaper>>(
              future: _wallpapers,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_outlined, color: Colors.white.withOpacity(0.6)),
                        SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.wallpaperRepoError,
                            style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final wallpapers = snapshot.data!;
                return GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: TvTokens.heroAspectRatio,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (var i = 0; i < wallpapers.length; i++)
                      EnsureVisible(alignment: 0.5, child: _wallpaperCard(wallpapers[i], autofocus: i == 0)),
                  ],
                );
              },
            ),
          ),
        ],
      );

  Widget _wallpaperCard(RepoWallpaper wallpaper, {bool autofocus = false}) => Focus(
        key: Key("repo-wallpaper-${wallpaper.category}"),
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
                    autofocus: autofocus,
                    onTap: () => _setWallpaper(context, wallpaper),
                    child: Image.network(
                      wallpaper.url.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.broken_image_outlined, color: Colors.white.withOpacity(0.4)),
                      ),
                    ),
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
                  child: Text(wallpaper.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _setWallpaper(BuildContext context, RepoWallpaper wallpaper) async {
    final bytes = await widget.repoService.downloadWallpaper(wallpaper);
    await context.read<WallpaperService>().setLocalWallpaper(bytes);
  }

  ShapeBorder? _cardBorder(bool hasFocus) => hasFocus
      ? RoundedRectangleBorder(
          side: BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(Glass.radiusSmall),
        )
      : null;
}
