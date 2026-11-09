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
import 'package:flauncher/widgets/right_panel_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class AppSearchDialog extends StatefulWidget {
  @override
  State<AppSearchDialog> createState() => _AppSearchDialogState();
}

class _AppSearchDialogState extends State<AppSearchDialog> {
  String _query = "";

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final apps = context.watch<AppsService>().applications.where((app) {
      final query = _query.trim().toLowerCase();
      return query.isEmpty || app.name.toLowerCase().contains(query);
    }).toList();
    return RightPanelDialog(
      width: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.searchApps,
              style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 12),
          TextField(
            key: Key("app-search-field"),
            autofocus: true,
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.searchApps,
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          SizedBox(height: 12),
          Expanded(
            child: apps.isEmpty
                ? Text(l10n.noSearchResults)
                : ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (context, index) => _result(apps[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _result(App app) => ListTile(
        key: Key("search-${app.packageName}"),
        title: Text(app.name),
        onTap: () {
          Navigator.of(context).pop();
          context.read<AppsService>().launchApp(app);
        },
      );
}
