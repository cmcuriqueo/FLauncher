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

import 'dart:typed_data';

import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

void main() {
  test("refresh maps channel programs to items", () async {
    final channel = MockFLauncherChannel();
    when(channel.getWatchNextPrograms()).thenAnswer((_) async => [
          {
            "title": "Episode 4",
            "packageName": "com.netflix.ninja",
            "intentUri": "intent://watch/4#Intent;end",
            "progress": 0.42,
            "poster": Uint8List.fromList([1, 2, 3]),
          },
          {"title": ""},
        ]);

    final service = WatchNextService(channel);
    await service.refresh();

    expect(service.items, hasLength(1));
    final item = service.firstItem!;
    expect(item.title, "Episode 4");
    expect(item.packageName, "com.netflix.ninja");
    expect(item.intentUri, "intent://watch/4#Intent;end");
    expect(item.progress, 0.42);
    expect(item.poster, isNotNull);
  });

  test("refresh swallows channel errors and yields empty list", () async {
    final channel = MockFLauncherChannel();
    when(channel.getWatchNextPrograms()).thenThrow(Exception("no tv provider"));

    final service = WatchNextService(channel);
    await service.refresh();

    expect(service.items, isEmpty);
    expect(service.firstItem, isNull);
  });

  test("launchItem forwards the intent uri to the channel", () async {
    final channel = MockFLauncherChannel();
    when(channel.getWatchNextPrograms()).thenAnswer((_) async => []);
    when(channel.launchIntentUri(any)).thenAnswer((_) async => true);

    final service = WatchNextService(channel);
    final launched = await service.launchItem(WatchNextItem(title: "t", intentUri: "intent://x#Intent;end"));

    expect(launched, isTrue);
    verify(channel.launchIntentUri("intent://x#Intent;end"));
  });

  test("launchItem returns false without intent uri", () async {
    final channel = MockFLauncherChannel();
    when(channel.getWatchNextPrograms()).thenAnswer((_) async => []);

    final service = WatchNextService(channel);

    expect(await service.launchItem(WatchNextItem(title: "t")), isFalse);
  });
}
