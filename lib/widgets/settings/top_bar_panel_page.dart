/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class TopBarPanelPage extends StatelessWidget {
  static const String routeName = "top_bar_panel";

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SettingsService>(
      builder: (context, settings, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.topBar, style: Theme.of(context).textTheme.titleLarge),
          Divider(),
          SwitchListTile(
            key: Key("show-date-setting"),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.showDate),
            value: settings.showDate,
            onChanged: settings.setShowDate,
          ),
          SwitchListTile(
            key: Key("show-network-setting"),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.showNetworkStatus),
            value: settings.showNetworkStatus,
            onChanged: settings.setShowNetworkStatus,
          ),
          SwitchListTile(
            key: Key("show-ip-setting"),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.showLocalIpAddress),
            value: settings.showLocalIpAddress,
            onChanged: settings.setShowLocalIpAddress,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.showNextAlarm),
            value: settings.showNextAlarm,
            onChanged: settings.setShowNextAlarm,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.showWeather),
            value: settings.showWeather,
            onChanged: settings.setShowWeather,
          ),
        ],
      ),
    );
  }
}
