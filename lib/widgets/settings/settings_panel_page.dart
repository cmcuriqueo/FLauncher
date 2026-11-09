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

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/gradients.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/network_diagnostics_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';
import 'package:flauncher/widgets/settings/categories_panel_page.dart';
import 'package:flauncher/widgets/settings/flauncher_about_dialog.dart';
import 'package:flauncher/widgets/settings/network_diagnostics_panel_page.dart';
import 'package:flauncher/widgets/settings/remote_control_panel_page.dart';
import 'package:flauncher/widgets/settings/top_bar_panel_page.dart';
import 'package:flauncher/widgets/settings/wallpaper_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class SettingsPanelPage extends StatelessWidget {
  static const String routeName = "settings_panel";

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SettingsService>(
      builder: (context, settingsService, __) => SingleChildScrollView(
        child: Column(
          children: [
            Text(l10n.settings, style: Theme.of(context).textTheme.titleLarge),
            Divider(),
            EnsureVisible(
              alignment: 0.5,
              child: TextButton(
                child: Row(
                  children: [
                    Icon(Icons.apps),
                    Container(width: 8),
                    Text(l10n.applications,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                onPressed: () => Navigator.of(context)
                    .pushNamed(ApplicationsPanelPage.routeName),
              ),
            ),
            TextButton(
              child: Row(
                children: [
                  Icon(Icons.category),
                  Container(width: 8),
                  Text(l10n.categories,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              onPressed: () => Navigator.of(context)
                  .pushNamed(CategoriesPanelPage.routeName),
            ),
            TextButton(
              child: Row(
                children: [
                  Icon(Icons.wallpaper_outlined),
                  Container(width: 8),
                  Text(l10n.wallpaper,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              onPressed: () =>
                  Navigator.of(context).pushNamed(WallpaperPanelPage.routeName),
            ),
            TextButton(
              child: Row(
                children: [
                  Icon(Icons.network_check),
                  Container(width: 8),
                  Text(l10n.networkDiagnostics,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              onPressed: () {
                context.read<NetworkDiagnosticsService>().refreshDetails();
                Navigator.of(context)
                    .pushNamed(NetworkDiagnosticsPanelPage.routeName);
              },
            ),
            TextButton(
              child: Row(
                children: [
                  Icon(Icons.settings_remote),
                  Container(width: 8),
                  Text(l10n.remoteControl,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              onPressed: () => Navigator.of(context)
                  .pushNamed(RemoteControlPanelPage.routeName),
            ),
            TextButton(
              child: Row(
                children: [
                  Icon(Icons.vertical_align_top),
                  Container(width: 8),
                  Text(l10n.topBar,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              onPressed: () =>
                  Navigator.of(context).pushNamed(TopBarPanelPage.routeName),
            ),
            TextButton(
              child: Row(
                children: [
                  Icon(Icons.upload_outlined),
                  Container(width: 8),
                  Text(l10n.exportBackup,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              onPressed: () async {
                final json = jsonEncode(
                    context.read<AppsService>().exportBackup());
                await context.read<FLauncherChannel>().saveBackup(json);
              },
            ),
            TextButton(
              child: Row(
                children: [
                  Icon(Icons.download_outlined),
                  Container(width: 8),
                  Text(l10n.importBackup,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              onPressed: () async {
                final raw = await context.read<FLauncherChannel>().readBackup();
                if (raw == null) return;
                try {
                  await context.read<AppsService>().importBackup(
                      Map<String, dynamic>.from(jsonDecode(raw) as Map));
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.backupFailed)));
                }
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.screensaverBackground,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  DropdownButton<String?>(
                    value: FLauncherGradients.all.any((gradient) =>
                            gradient.uuid ==
                            settingsService.screensaverGradientUuid)
                        ? settingsService.screensaverGradientUuid
                        : null,
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.currentWallpaper),
                      ),
                      ...FLauncherGradients.all.map(
                        (gradient) => DropdownMenuItem<String?>(
                          value: gradient.uuid,
                          child: Text(gradient.name),
                        ),
                      ),
                    ],
                    onChanged: settingsService.setScreensaverGradientUuid,
                  ),
                ],
              ),
            ),
            Divider(),
            TextButton(
              child: Row(
                children: [
                  Icon(Icons.settings_outlined),
                  Container(width: 8),
                  Text(l10n.androidSettings,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              onPressed: () => context.read<AppsService>().openSettings(),
            ),
            Divider(),
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 14),
              dense: true,
              title: Text(l10n.language),
              trailing: DropdownButton<String>(
                value: settingsService.languageCode,
                isDense: true,
                underline: SizedBox.shrink(),
                items: [
                  DropdownMenuItem(
                      value: null, child: Text(l10n.systemDefault)),
                  DropdownMenuItem(value: "en", child: Text("English")),
                  DropdownMenuItem(value: "es", child: Text("Español")),
                ],
                onChanged: (value) => settingsService.setLanguageCode(value),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 14),
              value: settingsService.use24HourTimeFormat,
              onChanged: (value) =>
                  settingsService.setUse24HourTimeFormat(value),
              title: Text(l10n.use24HourTimeFormat),
              dense: true,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 14),
              value: settingsService.appHighlightAnimationEnabled,
              onChanged: (value) =>
                  settingsService.setAppHighlightAnimationEnabled(value),
              title: Text(l10n.appCardHighlightAnimation),
              dense: true,
            ),
            Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 14),
              value: settingsService.crashReportsEnabled,
              onChanged: (value) =>
                  settingsService.setCrashReportsEnabled(value),
              title: Text(l10n.crashReporting),
              dense: true,
              subtitle: Text(l10n.crashReportingSubtitle),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 14),
              value: settingsService.analyticsEnabled,
              onChanged: (value) => settingsService.setAnalyticsEnabled(value),
              title: Text(l10n.analyticsReporting),
              dense: true,
              subtitle: Text(l10n.analyticsReportingSubtitle),
            ),
            Divider(),
            TextButton(
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  Container(width: 8),
                  Text(l10n.aboutFLauncher,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) =>
                      snapshot.connectionState == ConnectionState.done
                          ? FLauncherAboutDialog(packageInfo: snapshot.data!)
                          : Container(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
