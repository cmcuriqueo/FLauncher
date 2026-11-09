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

import 'package:flauncher/providers/next_alarm_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("refresh notifies listeners only when the next alarm changes", () async {
    final channel = MockFLauncherChannel();
    when(channel.getNextAlarm()).thenAnswer((_) async => 1700000000000);

    final service = NextAlarmService(channel);
    await service.refresh();
    var notifications = 0;
    service.addListener(() => notifications++);

    await service.refresh();
    expect(notifications, 0);

    when(channel.getNextAlarm()).thenAnswer((_) async => 1700000060000);
    await service.refresh();
    expect(notifications, 1);
    service.dispose();
  });
}
