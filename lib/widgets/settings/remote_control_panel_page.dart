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
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/remote_control.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class RemoteControlPanelPage extends StatefulWidget {
  static const String routeName = "remote_control_panel";

  @override
  State<RemoteControlPanelPage> createState() => _RemoteControlPanelPageState();
}

class _RemoteControlPanelPageState extends State<RemoteControlPanelPage> {
  String? _listeningPackage;
  String? _listeningName;

  @override
  Widget build(BuildContext context) => Focus(
        canRequestFocus: false,
        onKey: (_, event) => _captureKey(event),
        child: Consumer2<SettingsService, AppsService>(
          builder: (context, settingsService, appsService, _) {
            final l10n = AppLocalizations.of(context)!;
            final applications =
                appsService.applications.where((app) => !app.hidden).toList();
            final otherApplications = applications
                .where((app) =>
                    app.packageName != netflixPackageName &&
                    app.packageName != youtubePackageName)
                .toList();
            return Column(
              children: [
                Text(l10n.remoteControl,
                    style: Theme.of(context).textTheme.titleLarge),
                Divider(),
                if (_listeningPackage != null)
                  Card(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(
                                  l10n.pressRemoteButton(_listeningName!))),
                          TextButton(
                            onPressed: () => setState(() {
                              _listeningPackage = null;
                              _listeningName = null;
                            }),
                            child: Text(l10n.cancel),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(l10n.remoteControlDescription,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                      _appTile(context, settingsService, applications,
                          netflixPackageName, "Netflix"),
                      _appTile(context, settingsService, applications,
                          youtubePackageName, "YouTube"),
                      if (otherApplications.isNotEmpty) ...[
                        Divider(),
                        ...otherApplications.map((app) => EnsureVisible(
                              alignment: 0.5,
                              child: _appTile(context, settingsService,
                                  applications, app.packageName, app.name),
                            )),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

  Widget _appTile(
    BuildContext context,
    SettingsService settingsService,
    List<App> applications,
    String packageName,
    String name,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final installed = applications.any((app) => app.packageName == packageName);
    final mappings = settingsService.remoteShortcuts.entries
        .where((entry) => entry.value == packageName)
        .toList();
    final keyCode = mappings.isEmpty ? null : mappings.first.key;
    return ListTile(
      key: Key("remote-shortcut-$packageName"),
      dense: true,
      enabled: installed,
      title: Text(name, style: Theme.of(context).textTheme.bodyMedium),
      subtitle: Text(!installed
          ? l10n.notInstalled
          : keyCode != null
              ? l10n.remoteButton(keyCode)
              : l10n.assignRemoteButton),
      trailing: keyCode == null
          ? null
          : IconButton(
              key: Key("remove-remote-shortcut-$packageName"),
              constraints: BoxConstraints(),
              splashRadius: 20,
              tooltip: l10n.delete,
              icon: Icon(Icons.delete_outline),
              onPressed: () => settingsService.removeRemoteShortcut(keyCode),
            ),
      onTap: installed
          ? () => setState(() {
                _listeningPackage = packageName;
                _listeningName = name;
              })
          : null,
    );
  }

  KeyEventResult _captureKey(RawKeyEvent event) {
    final packageName = _listeningPackage;
    final keyCode = remoteShortcutKeyCode(event);
    if (packageName == null || keyCode == null) return KeyEventResult.ignored;

    context.read<SettingsService>().setRemoteShortcut(keyCode, packageName);
    setState(() {
      _listeningPackage = null;
      _listeningName = null;
    });
    return KeyEventResult.handled;
  }
}
