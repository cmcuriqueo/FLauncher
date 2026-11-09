/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

import 'dart:convert';
import 'dart:io';

import 'package:flauncher/providers/network_diagnostics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

void main() {
  test("calculates latency, loss, jitter and transfer speeds", () async {
    final channel = MockFLauncherChannel();
    when(channel.getNetworkDetails()).thenAnswer((_) async => {
          "gateway": "192.168.1.1",
          "dnsServers": ["1.1.1.1", "8.8.8.8"],
          "vpnActive": true,
          "wifiSignal": -55,
          "wifiFrequency": 5180,
          "wifiLinkSpeed": 866,
        });
    final transport = FakeTransport(latencies: [10, 14, 12, null, 20]);
    final timestamp = DateTime(2026, 1, 2, 3, 4);
    final service =
        NetworkDiagnosticsService(channel, transport, now: () => timestamp);

    await service.startTest();

    final result = service.lastResult!;
    expect(result.downloadMbps, 80);
    expect(result.uploadMbps, 10);
    expect(result.minimumLatency, 10);
    expect(result.averageLatency, 14);
    expect(result.maximumLatency, 20);
    expect(result.packetLoss, 20);
    expect(result.jitter, closeTo(4.666666, 0.0001));
    expect(result.stability, "unstable");
    expect(result.timestamp, timestamp);
    expect(result.server, networkDiagnosticsServer);
    expect(service.details.gateway, "192.168.1.1");
    expect(service.details.dnsServers, ["1.1.1.1", "8.8.8.8"]);
    expect(service.details.vpnActive, isTrue);
    expect(service.details.wifiSignal, -55);
    expect(service.error, isNull);
    expect(service.running, isFalse);
    expect(service.progress, isNull);
    expect(transport.downloadRequests, [8000000]);
    expect(transport.uploadRequests, [1000000]);
  });

  test("classifies a low-jitter connection as stable", () async {
    final service = NetworkDiagnosticsService(
        MockFLauncherChannel(), FakeTransport(latencies: [20, 22, 21, 20, 21]));
    await service.startTest();
    expect(service.lastResult!.stability, "stable");
  });

  test("keeps the last result and reports a failed test", () async {
    final service = NetworkDiagnosticsService(MockFLauncherChannel(),
        FakeTransport(latencies: [null, null, null, null, null]));
    await service.startTest();
    expect(service.lastResult, isNull);
    expect(service.error, "failed");
    expect(service.running, isFalse);

    await service.startTest();
    expect(service.lastResult, isNull);
  });

  test("does not start concurrent tests", () async {
    final service = NetworkDiagnosticsService(
        MockFLauncherChannel(), FakeTransport(latencies: [10, 10, 10, 10, 10]));
    final first = service.startTest();
    final second = service.startTest();
    await Future.wait([first, second]);
    expect(service.lastResult, isNotNull);
  });

  test("restores a valid last result and rejects malformed data", () {
    final result = NetworkDiagnosticsResult(
      downloadMbps: 80,
      uploadMbps: 10,
      minimumLatency: 10,
      averageLatency: 14,
      maximumLatency: 20,
      packetLoss: 0,
      jitter: 2,
      timestamp: DateTime.utc(2026),
      server: networkDiagnosticsServer,
    );
    final restored =
        NetworkDiagnosticsResult.tryFromJson(jsonEncode(result.toJson()));
    expect(restored!.timestamp, DateTime.utc(2026));
    expect(restored.downloadMbps, 80);
    expect(NetworkDiagnosticsResult.tryFromJson("not-json"), isNull);
  });
}

class FakeTransport implements NetworkDiagnosticsTransport {
  final List<int?> latencies;
  final downloadRequests = <int>[];
  final uploadRequests = <int>[];
  var latencyIndex = 0;

  FakeTransport({required this.latencies});

  @override
  Future<int> measureLatency() async {
    final value = latencies[latencyIndex++];
    if (value == null) throw SocketException("Failed");
    return value;
  }

  @override
  Future<double> measureDownload(int bytes) async {
    downloadRequests.add(bytes);
    return 80;
  }

  @override
  Future<double> measureUpload(int bytes) async {
    uploadRequests.add(bytes);
    return 10;
  }
}
