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

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Fetches the curated wallpaper collection hosted in a plain git repository
/// (no API key). The repo serves a `manifest.json` listing the wallpapers,
/// each entry pointing to an image file served from the same base URL.
class WallpaperRepoService {
  static const String _baseUrl = "https://raw.githubusercontent.com/cmcuriqueo/flauncher-wallpapers/main";

  final http.Client _client;

  WallpaperRepoService([http.Client? client]) : _client = client ?? http.Client();

  Future<List<RepoWallpaper>> fetchWallpapers() async {
    final response = await _client.get(Uri.parse("$_baseUrl/manifest.json"));
    if (response.statusCode != 200) {
      throw WallpaperRepoException("manifest");
    }
    final manifest = jsonDecode(response.body) as Map<String, dynamic>;
    return (manifest["wallpapers"] as List<dynamic>)
        .map((entry) => RepoWallpaper(
              name: entry["name"] as String,
              category: entry["category"] as String,
              url: Uri.parse("$_baseUrl/${entry["file"]}"),
            ))
        .toList();
  }

  Future<Uint8List> downloadWallpaper(RepoWallpaper wallpaper) async {
    final response = await _client.get(wallpaper.url);
    if (response.statusCode != 200) {
      throw WallpaperRepoException(wallpaper.url.toString());
    }
    return response.bodyBytes;
  }
}

class RepoWallpaper {
  final String name;
  final String category;
  final Uri url;

  RepoWallpaper({required this.name, required this.category, required this.url});
}

class WallpaperRepoException implements Exception {
  final String resource;

  WallpaperRepoException(this.resource);

  @override
  String toString() => "WallpaperRepoException: failed to fetch $resource";
}
