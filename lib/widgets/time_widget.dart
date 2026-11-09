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

import 'dart:async';
import 'dart:ui';

import 'package:flauncher/providers/next_alarm_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TimeWidget extends StatefulWidget {
  @override
  _TimeWidgetState createState() => _TimeWidgetState();
}

class _TimeWidgetState extends State<TimeWidget> {
  late DateTime _now;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _scheduleNextMinuteRefresh();
  }

  void _scheduleNextMinuteRefresh() {
    final now = DateTime.now();
    final nextMinute =
        DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    _timer = Timer(nextMinute.difference(now), () {
      if (!mounted) return;
      _refreshTime();
      _scheduleNextMinuteRefresh();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<SettingsService>(
        builder: (context, settingsService, _) {
          final alarm = settingsService.showNextAlarm
              ? context.watch<NextAlarmService>().nextAlarm
              : null;
          final weather = settingsService.showWeather
              ? context.watch<WeatherService>().report
              : null;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                settingsService.use24HourTimeFormat
                    ? DateFormat.Hm().format(_now)
                    : DateFormat.jm().format(_now),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                textAlign: TextAlign.end,
              ),
              if (settingsService.showDate || weather != null || alarm != null)
                Text(
                  [
                    if (settingsService.showDate)
                      DateFormat.MMMEd(
                              Localizations.localeOf(context).toLanguageTag())
                          .format(_now),
                    if (weather != null) "${weather.temperature.round()}°",
                    if (alarm != null)
                      "${AppLocalizations.of(context)!.nextAlarm} ${settingsService.use24HourTimeFormat ? DateFormat.Hm().format(alarm) : DateFormat.jm().format(alarm)}",
                  ].join(" · "),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          );
        },
      );

  void _refreshTime() {
    setState(() {
      _now = DateTime.now();
    });
  }
}
