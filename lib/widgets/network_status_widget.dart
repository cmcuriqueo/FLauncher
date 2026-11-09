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

import 'package:flauncher/providers/network_status_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class NetworkStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Consumer2<NetworkStatusService, SettingsService>(
        builder: (context, service, settings, _) {
          final status = service.status;
          final localizations = AppLocalizations.of(context)!;
          final label = _statusLabel(localizations, status);
          final ipAddress =
              settings.showLocalIpAddress ? status.ipAddress : null;
          return Semantics(
            label: ipAddress == null ? label : "$label, IP $ipAddress",
            child: Row(
              key: Key("network-status"),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _statusIcon(status),
                  size: 22,
                  color: status.hasInternet ? Glass.green : Glass.red,
                ),
                SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodyMedium),
                    if (ipAddress != null)
                      Text(
                        "IP $ipAddress",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      );

  String _statusLabel(AppLocalizations localizations, NetworkStatus status) {
    if (status.connectionType == NetworkConnectionType.unknown)
      return localizations.checkingConnection;
    if (status.connectionType == NetworkConnectionType.none)
      return localizations.noConnection;
    return status.hasInternet
        ? localizations.connected
        : localizations.noInternet;
  }

  IconData _statusIcon(NetworkStatus status) {
    if (status.connectionType == NetworkConnectionType.none)
      return Icons.cloud_off_outlined;
    if (status.connectionType == NetworkConnectionType.unknown)
      return Icons.cloud_queue;
    if (!status.hasInternet) return Icons.cloud_off_outlined;
    switch (status.connectionType) {
      case NetworkConnectionType.wifi:
        return Icons.wifi;
      case NetworkConnectionType.ethernet:
        return Icons.settings_ethernet;
      case NetworkConnectionType.other:
        return Icons.cloud_done_outlined;
      case NetworkConnectionType.unknown:
      case NetworkConnectionType.none:
        return Icons.cloud_off_outlined;
    }
  }
}
