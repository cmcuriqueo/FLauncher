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

class BackupCategory {
  final String name;
  final CategorySort sort;
  final CategoryType type;
  final int rowHeight;
  final int columnsCount;
  final int order;
  final List<String> apps;

  BackupCategory({
    required this.name,
    required this.sort,
    required this.type,
    required this.rowHeight,
    required this.columnsCount,
    required this.order,
    required this.apps,
  });
}

class LauncherBackupData {
  final List<BackupCategory> categories;
  final List<String> favorites;
  final Map<String, dynamic> preferences;

  LauncherBackupData({
    required this.categories,
    required this.favorites,
    required this.preferences,
  });
}

class LauncherBackup {
  static const version = 1;

  static Map<String, dynamic> encode({
    required List<CategoryWithApps> categories,
    required List<String> favorites,
    required Map<String, dynamic> preferences,
  }) =>
      {
        "version": version,
        "categories": categories
            .map((entry) => {
                  "name": entry.category.name,
                  "sort": entry.category.sort.name,
                  "type": entry.category.type.name,
                  "rowHeight": entry.category.rowHeight,
                  "columnsCount": entry.category.columnsCount,
                  "order": entry.category.order,
                  "apps": entry.applications
                      .map((app) => app.packageName)
                      .toList(),
                })
            .toList(),
        "favorites": favorites,
        "preferences": preferences,
      };

  static LauncherBackupData decode(Map<String, dynamic> json) {
    if (json["version"] != version) {
      throw FormatException("Unsupported backup");
    }
    final categories = (json["categories"] as List<dynamic>? ?? [])
        .map((raw) => _category(Map<String, dynamic>.from(raw as Map)))
        .toList();
    final favorites = (json["favorites"] as List<dynamic>? ?? [])
        .map((item) => item as String)
        .toList();
    final preferences = Map<String, dynamic>.from(
        json["preferences"] as Map? ?? <String, dynamic>{});
    return LauncherBackupData(
      categories: categories,
      favorites: favorites,
      preferences: preferences,
    );
  }

  static BackupCategory _category(Map<String, dynamic> json) => BackupCategory(
        name: json["name"] as String,
        sort: CategorySort.values.byName(json["sort"] as String? ?? "manual"),
        type: CategoryType.values.byName(json["type"] as String? ?? "row"),
        rowHeight: json["rowHeight"] as int? ?? 110,
        columnsCount: json["columnsCount"] as int? ?? 6,
        order: json["order"] as int? ?? 0,
        apps: (json["apps"] as List<dynamic>? ?? [])
            .map((item) => item as String)
            .toList(),
      );
}
