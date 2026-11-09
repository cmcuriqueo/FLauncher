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

import 'package:flauncher/gradients.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Screensaver extends StatefulWidget {
  @override
  State<Screensaver> createState() => _ScreensaverState();
}

class _ScreensaverState extends State<Screensaver> {
  late DateTime _now;
  late Timer _timer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    HardwareKeyboard.instance.addHandler(_exitOnKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    _scheduleNextMinuteRefresh();
  }

  void _scheduleNextMinuteRefresh() {
    final now = DateTime.now();
    final nextMinute =
        DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    _timer = Timer(nextMinute.difference(now), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _scheduleNextMinuteRefresh();
    });
  }

  bool _exitOnKey(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted) return false;
    Navigator.of(context).maybePop();
    return true;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_exitOnKey);
    _timer.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallpaper = context.watch<WallpaperService>();
    final settings = context.watch<SettingsService>();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final gradientId = settings.screensaverGradientUuid;
    final chosenGradient = gradientId == null
        ? null
        : FLauncherGradients.all
            .cast<FLauncherGradient?>()
            .firstWhere((item) => item!.uuid == gradientId, orElse: () => null);
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (_, event) {
        if (event is RawKeyDownEvent && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return KeyEventResult.handled;
      },
      child: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              chosenGradient != null
                  ? DecoratedBox(
                      decoration:
                          BoxDecoration(gradient: chosenGradient.gradient))
                  : wallpaper.wallpaperBytes == null
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: wallpaper.gradient.gradient))
                      : Image.memory(wallpaper.wallpaperBytes!,
                          fit: BoxFit.cover,
                          cacheWidth: (MediaQuery.of(context).size.width *
                                  MediaQuery.of(context).devicePixelRatio)
                              .round()),
              DecoratedBox(
                decoration:
                    BoxDecoration(color: Colors.black.withOpacity(0.32)),
              ),
              Center(
                child: GlassContainer(
                  radius: Glass.radiusLarge,
                  padding: EdgeInsets.symmetric(horizontal: 56, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        settings.use24HourTimeFormat
                            ? DateFormat.Hm(locale).format(_now)
                            : DateFormat.jm(locale).format(_now),
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      if (settings.showDate)
                        Text(
                          DateFormat.yMMMMEEEEd(locale).format(_now),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.screensaverExit,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
