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

import 'package:flauncher/providers/storage_status_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("refresh reports low storage below 1 GiB", () async {
    final channel = MockFLauncherChannel();
    when(channel.getStorageStatus()).thenAnswer((_) async => {
          "totalBytes": 32 * 1024 * 1024 * 1024,
          "freeBytes": 512 * 1024 * 1024,
        });

    final service = StorageStatusService(channel);
    await service.refresh();

    expect(service.status.known, isTrue);
    expect(service.status.low, isTrue);
    expect(formatStorageBytes(service.status.freeBytes), "512 MB");
    service.dispose();
  });

  test("refresh keeps healthy storage quiet", () async {
    final channel = MockFLauncherChannel();
    when(channel.getStorageStatus()).thenAnswer((_) async => {
          "totalBytes": 32 * 1024 * 1024 * 1024,
          "freeBytes": 16 * 1024 * 1024 * 1024,
        });

    final service = StorageStatusService(channel);
    await service.refresh();

    expect(service.status.low, isFalse);
    service.dispose();
  });

  test("refresh reports unknown storage when the channel fails", () async {
    final channel = MockFLauncherChannel();
    when(channel.getStorageStatus()).thenThrow(Exception("not available"));

    final service = StorageStatusService(channel);
    await service.refresh();

    expect(service.status.known, isFalse);
    expect(service.status.low, isFalse);
    service.dispose();
  });

  test("refresh notifies listeners only when the status changes", () async {
    final channel = MockFLauncherChannel();
    when(channel.getStorageStatus()).thenAnswer((_) async => {
          "totalBytes": 32 * 1024 * 1024 * 1024,
          "freeBytes": 16 * 1024 * 1024 * 1024,
        });

    final service = StorageStatusService(channel);
    await service.refresh();
    var notifications = 0;
    service.addListener(() => notifications++);

    await service.refresh();
    expect(notifications, 0);

    when(channel.getStorageStatus()).thenAnswer((_) async => {
          "totalBytes": 32 * 1024 * 1024 * 1024,
          "freeBytes": 8 * 1024 * 1024 * 1024,
        });
    await service.refresh();
    expect(notifications, 1);
    service.dispose();
  });
}
