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

import 'package:flauncher/flauncher_channel.dart';
import 'package:flutter/foundation.dart';

class WatchNextItem {
  final String title;
  final String? packageName;
  final String? intentUri;
  final double? progress;
  final Uint8List? poster;

  WatchNextItem({
    required this.title,
    this.packageName,
    this.intentUri,
    this.progress,
    this.poster,
  });
}

/// Exposes the Android TV "Watch Next" channel (content that apps publish as
/// partially watched). Empty when no app publishes to the channel or when the
/// platform refuses the query.
class WatchNextService extends ChangeNotifier {
  final FLauncherChannel _fLauncherChannel;

  List<WatchNextItem> _items = [];

  List<WatchNextItem> get items => _items;

  WatchNextItem? get firstItem => _items.isNotEmpty ? _items.first : null;

  WatchNextService(this._fLauncherChannel) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final programs = await _fLauncherChannel.getWatchNextPrograms();
      _items = programs
          .map((program) => WatchNextItem(
                title: program["title"] as String? ?? "",
                packageName: program["packageName"] as String?,
                intentUri: program["intentUri"] as String?,
                progress: (program["progress"] as num?)?.toDouble(),
                poster: program["poster"] as Uint8List?,
              ))
          .where((item) => item.title.isNotEmpty)
          .toList();
    } catch (_) {
      _items = [];
    }
    notifyListeners();
  }

  Future<bool> launchItem(WatchNextItem item) async {
    final intentUri = item.intentUri;
    if (intentUri == null) return false;
    return _fLauncherChannel.launchIntentUri(intentUri);
  }
}
