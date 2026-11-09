/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/network_diagnostics_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NetworkDiagnosticsPanelPage extends StatelessWidget {
  static const String routeName = "network_diagnostics_panel";

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer2<SettingsService, NetworkDiagnosticsService>(
      builder: (context, settingsService, service, _) {
        final result =
            service.lastResult ?? settingsService.lastNetworkDiagnostics;
        return Column(
          children: [
            Text(l10n.networkDiagnostics,
                style: Theme.of(context).textTheme.titleLarge),
            Divider(),
            Expanded(
              child: ListView(
                children: [
                  Text(l10n.networkDiagnosticsDescription,
                      style: Theme.of(context).textTheme.bodySmall),
                  SizedBox(height: 12),
                  EnsureVisible(
                    alignment: 0.5,
                    child: ElevatedButton.icon(
                      key: Key("start-network-test"),
                      icon: Icon(Icons.speed),
                      label: Text(service.running
                          ? l10n.networkTestRunning
                          : l10n.startNetworkTest),
                      onPressed: service.running
                          ? null
                          : () => _startTest(context, service),
                    ),
                  ),
                  if (service.progress != null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  _progressLabel(l10n, service.progress!))),
                        ],
                      ),
                    ),
                  if (service.error != null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(l10n.networkTestFailed,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ),
                  if (result != null) ...[
                    Divider(),
                    _resultRow(l10n.downloadSpeed,
                        "${result.downloadMbps.toStringAsFixed(1)} Mbps"),
                    _resultRow(l10n.uploadSpeed,
                        "${result.uploadMbps.toStringAsFixed(1)} Mbps"),
                    _resultRow(
                        l10n.latency,
                        l10n.latencyValues(
                            result.minimumLatency.round(),
                            result.averageLatency.round(),
                            result.maximumLatency.round())),
                    _resultRow(l10n.packetLoss,
                        "${result.packetLoss.toStringAsFixed(0)}%"),
                    _resultRow(
                        l10n.jitter, "${result.jitter.toStringAsFixed(1)} ms"),
                    _resultRow(l10n.connectionStability,
                        _stabilityLabel(l10n, result.stability)),
                    SizedBox(height: 8),
                    Text(
                      l10n.lastNetworkTest(
                          DateFormat.yMd(
                                  Localizations.localeOf(context).toString())
                              .add_Hm()
                              .format(result.timestamp.toLocal()),
                          result.server),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  Divider(),
                  _resultRow(l10n.gateway,
                      service.details.gateway ?? l10n.notAvailable),
                  _resultRow(
                      l10n.dnsServers,
                      service.details.dnsServers.isEmpty
                          ? l10n.notAvailable
                          : service.details.dnsServers.join(", ")),
                  _resultRow(l10n.vpn,
                      service.details.vpnActive ? l10n.active : l10n.inactive),
                  _resultRow(
                      l10n.wifiSignal,
                      service.details.wifiSignal == null
                          ? l10n.notAvailable
                          : "${service.details.wifiSignal} dBm"),
                  _resultRow(
                      l10n.wifiFrequency,
                      service.details.wifiFrequency == null
                          ? l10n.notAvailable
                          : "${service.details.wifiFrequency} MHz"),
                  _resultRow(
                      l10n.wifiLinkSpeed,
                      service.details.wifiLinkSpeed == null
                          ? l10n.notAvailable
                          : "${service.details.wifiLinkSpeed} Mbps"),
                  EnsureVisible(
                    alignment: 0.5,
                    child: TextButton.icon(
                      icon: Icon(Icons.settings_outlined),
                      label: Text(l10n.androidNetworkSettings),
                      onPressed: () => context
                          .read<FLauncherChannel>()
                          .openNetworkSettings(),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(l10n.httpsDiagnosticsNote,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _resultRow(String label, String value) => Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label)),
            SizedBox(width: 8),
            Flexible(child: Text(value, textAlign: TextAlign.end)),
          ],
        ),
      );

  Future<void> _startTest(
      BuildContext context, NetworkDiagnosticsService service) async {
    await service.startTest();
    if (service.lastResult != null && service.error == null) {
      await context
          .read<SettingsService>()
          .setLastNetworkDiagnostics(service.lastResult!);
    }
  }

  String _progressLabel(AppLocalizations l10n, String progress) {
    switch (progress) {
      case "download":
        return l10n.measuringDownload;
      case "upload":
        return l10n.measuringUpload;
      default:
        return l10n.measuringLatency;
    }
  }

  String _stabilityLabel(AppLocalizations l10n, String stability) {
    switch (stability) {
      case "stable":
        return l10n.stableConnection;
      case "fair":
        return l10n.fairConnection;
      default:
        return l10n.unstableConnection;
    }
  }
}
