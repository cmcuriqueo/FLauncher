/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

import 'dart:async';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/storage_status_service.dart';
import 'package:flauncher/widgets/glass.dart';
import 'package:flauncher/widgets/right_panel_dialog.dart';
import 'package:flauncher/widgets/screensaver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class QuickSettingsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final channel = context.read<FLauncherChannel>();
    return RightPanelDialog(
      width: 350,
      child: Column(
        children: [
          Text(l10n.quickSettings,
              style: Theme.of(context).textTheme.titleLarge),
          Divider(),
          Expanded(
            child: ListView(
              children: [
                _action(Icons.wifi, l10n.wifiSettings,
                    () => channel.openWifiSettings()),
                _action(Icons.bluetooth, l10n.bluetoothSettings,
                    () => channel.openBluetoothSettings()),
                _action(Icons.settings_ethernet, l10n.androidNetworkSettings,
                    () => channel.openNetworkSettings()),
                _action(Icons.bedtime_outlined, l10n.sleep,
                    () => _sleep(context, channel)),
                _action(Icons.screen_lock_portrait_outlined, l10n.screensaver,
                    () => _showScreensaver(context)),
                _storageTile(context, l10n, channel),
                _LauncherMemoryUsage(),
                _BluetoothDevices(),
              ],
            ),
          ),
          Text(l10n.quickSettingsNote,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _storageTile(
      BuildContext context, AppLocalizations l10n, FLauncherChannel channel) {
    final status = context.watch<StorageStatusService>().status;
    final free = status.known
        ? l10n.storageFree(
            formatStorageBytes(status.freeBytes),
            formatStorageBytes(status.totalBytes),
          )
        : l10n.storageUnavailable;
    final details = status.low ? "${l10n.storageLow} · $free" : free;
    return ListTile(
      key: Key("storage-status"),
      leading: Icon(Icons.storage, color: status.low ? Glass.red : null),
      title: Text(l10n.storage),
      subtitle: Text(details),
      trailing: Tooltip(message: l10n.manageApps, child: Icon(Icons.apps)),
      onTap: () => channel.openApplicationManagement(),
    );
  }

  Widget _action(
          IconData icon, String label, FutureOr<void> Function() action) =>
      Builder(
        builder: (context) => ListTile(
          leading: Icon(icon),
          title: Text(label),
          onTap: action,
        ),
      );

  Future<void> _sleep(BuildContext context, FLauncherChannel channel) async {
    final locked = await channel.lockScreen();
    if (!locked) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context)!.sleepAccessibilityRequired)));
    }
  }

  void _showScreensaver(BuildContext context) {
    Navigator.of(context).pop();
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => Screensaver(),
    );
  }
}

class _LauncherMemoryUsage extends StatefulWidget {
  @override
  State<_LauncherMemoryUsage> createState() => _LauncherMemoryUsageState();
}

class _LauncherMemoryUsageState extends State<_LauncherMemoryUsage> {
  bool _loaded = false;
  int? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes =
          await context.read<FLauncherChannel>().getLauncherMemoryUsage();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bytes = _bytes;
    final details = !_loaded
        ? l10n.loading
        : bytes == null
            ? l10n.launcherMemoryUnavailable
            : l10n.launcherMemoryUsed(formatStorageBytes(bytes));
    return ListTile(
      key: Key("launcher-memory-status"),
      leading: Icon(Icons.memory),
      title: Text(l10n.launcherMemory),
      subtitle: Text(details),
    );
  }
}

class _BluetoothDevices extends StatefulWidget {
  @override
  State<_BluetoothDevices> createState() => _BluetoothDevicesState();
}

class _BluetoothDevicesState extends State<_BluetoothDevices> {
  bool _available = false;
  List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final status =
          await context.read<FLauncherChannel>().getBluetoothStatus();
      if (!mounted) return;
      final devices = (status["devices"] as List<dynamic>? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      setState(() {
        _available = status["available"] == true;
        _devices = devices;
      });
    } catch (_) {
      if (mounted) setState(() => _available = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final connected =
        _devices.where((device) => device["connected"] == true).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(l10n.bluetoothDevices,
              style: Theme.of(context).textTheme.titleSmall),
        ),
        if (!_available || connected.isEmpty)
          ListTile(
            dense: true,
            title: Text(l10n.bluetoothUnavailable),
          )
        else
          ...connected.map((device) {
            final battery = device["battery"];
            final detail = battery is int
                ? l10n.bluetoothBattery(battery)
                : l10n.connected;
            return ListTile(
              dense: true,
              leading: Icon(Icons.bluetooth),
              title: Text(device["name"] as String? ?? ""),
              subtitle: Text(detail),
            );
          }),
      ],
    );
  }
}
