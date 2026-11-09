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
import 'dart:convert';
import 'dart:io';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flutter/foundation.dart';

const networkDiagnosticsServer = "Cloudflare (speed.cloudflare.com)";
const networkDiagnosticsServerKey = "speed.cloudflare.com";

class NetworkDetails {
  final String? gateway;
  final List<String> dnsServers;
  final bool vpnActive;
  final int? wifiSignal;
  final int? wifiFrequency;
  final int? wifiLinkSpeed;

  const NetworkDetails({
    this.gateway,
    this.dnsServers = const [],
    this.vpnActive = false,
    this.wifiSignal,
    this.wifiFrequency,
    this.wifiLinkSpeed,
  });

  factory NetworkDetails.fromMap(Map<String, dynamic> map) => NetworkDetails(
        gateway: map["gateway"] as String?,
        dnsServers: (map["dnsServers"] as List<dynamic>? ?? [])
            .whereType<String>()
            .toList(),
        vpnActive: map["vpnActive"] as bool? ?? false,
        wifiSignal: map["wifiSignal"] as int?,
        wifiFrequency: map["wifiFrequency"] as int?,
        wifiLinkSpeed: map["wifiLinkSpeed"] as int?,
      );
}

class NetworkDiagnosticsResult {
  final double downloadMbps;
  final double uploadMbps;
  final double minimumLatency;
  final double averageLatency;
  final double maximumLatency;
  final double packetLoss;
  final double jitter;
  final DateTime timestamp;
  final String server;

  const NetworkDiagnosticsResult({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.minimumLatency,
    required this.averageLatency,
    required this.maximumLatency,
    required this.packetLoss,
    required this.jitter,
    required this.timestamp,
    required this.server,
  });

  String get stability {
    if (packetLoss == 0 && jitter < 10) return "stable";
    if (packetLoss < 5 && jitter < 30) return "fair";
    return "unstable";
  }

  Map<String, dynamic> toJson() => {
        "downloadMbps": downloadMbps,
        "uploadMbps": uploadMbps,
        "minimumLatency": minimumLatency,
        "averageLatency": averageLatency,
        "maximumLatency": maximumLatency,
        "packetLoss": packetLoss,
        "jitter": jitter,
        "timestamp": timestamp.toIso8601String(),
        "server": server,
      };

  static NetworkDiagnosticsResult? tryFromJson(String? value) {
    if (value == null) return null;
    try {
      final map = jsonDecode(value) as Map<String, dynamic>;
      return NetworkDiagnosticsResult(
        downloadMbps: (map["downloadMbps"] as num).toDouble(),
        uploadMbps: (map["uploadMbps"] as num).toDouble(),
        minimumLatency: (map["minimumLatency"] as num).toDouble(),
        averageLatency: (map["averageLatency"] as num).toDouble(),
        maximumLatency: (map["maximumLatency"] as num).toDouble(),
        packetLoss: (map["packetLoss"] as num).toDouble(),
        jitter: (map["jitter"] as num).toDouble(),
        timestamp: DateTime.parse(map["timestamp"] as String),
        server: map["server"] as String,
      );
    } catch (_) {
      return null;
    }
  }
}

abstract class NetworkDiagnosticsTransport {
  Future<int> measureLatency();
  Future<double> measureDownload(int bytes);
  Future<double> measureUpload(int bytes);
}

class CloudflareNetworkDiagnosticsTransport
    implements NetworkDiagnosticsTransport {
  final HttpClient Function() clientFactory;
  final Duration timeout;

  CloudflareNetworkDiagnosticsTransport({
    HttpClient Function()? clientFactory,
    this.timeout = const Duration(seconds: 20),
  }) : clientFactory = clientFactory ?? (() => HttpClient());

  @override
  Future<int> measureLatency() async {
    final stopwatch = Stopwatch()..start();
    await _request(
        "GET", Uri.parse("https://speed.cloudflare.com/__down?bytes=0"));
    stopwatch.stop();
    return (stopwatch.elapsedMicroseconds / 1000).round();
  }

  @override
  Future<double> measureDownload(int bytes) async {
    final stopwatch = Stopwatch()..start();
    await _request(
        "GET", Uri.parse("https://speed.cloudflare.com/__down?bytes=$bytes"));
    stopwatch.stop();
    return _mbps(bytes, stopwatch.elapsed);
  }

  @override
  Future<double> measureUpload(int bytes) async {
    final stopwatch = Stopwatch()..start();
    await _request("POST", Uri.parse("https://speed.cloudflare.com/__up"),
        body: Uint8List(bytes));
    stopwatch.stop();
    return _mbps(bytes, stopwatch.elapsed);
  }

  double _mbps(int bytes, Duration elapsed) {
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    return seconds > 0 ? bytes * 8 / seconds / 1000000 : 0;
  }

  Future<void> _request(String method, Uri uri, {Uint8List? body}) async {
    final client = clientFactory();
    client.connectionTimeout = timeout;
    try {
      final request = await client.openUrl(method, uri).timeout(timeout);
      request.headers.set(HttpHeaders.userAgentHeader, "FLauncher/0.0.1");
      if (body != null) {
        request.contentLength = body.length;
        request.add(body);
      }
      final response = await request.close().timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain();
        throw HttpException("Server returned ${response.statusCode}", uri: uri);
      }
      await response.drain().timeout(timeout);
    } finally {
      client.close(force: true);
    }
  }
}

class NetworkDiagnosticsService extends ChangeNotifier {
  static const latencySamples = 5;
  static const downloadBytes = 8000000;
  static const uploadBytes = 1000000;

  final FLauncherChannel channel;
  final NetworkDiagnosticsTransport transport;
  final DateTime Function() now;

  NetworkDiagnosticsResult? _lastResult;
  NetworkDetails _details = NetworkDetails();
  bool _running = false;
  String? _progress;
  String? _error;

  NetworkDiagnosticsService(
    this.channel,
    this.transport, {
    NetworkDiagnosticsResult? lastResult,
    DateTime Function()? now,
  })  : _lastResult = lastResult,
        now = now ?? (() => DateTime.now());

  NetworkDiagnosticsResult? get lastResult => _lastResult;
  NetworkDetails get details => _details;
  bool get running => _running;
  String? get progress => _progress;
  String? get error => _error;

  Future<void> refreshDetails() async {
    try {
      _details = NetworkDetails.fromMap(await channel.getNetworkDetails());
    } catch (_) {
      _details = NetworkDetails();
    }
    notifyListeners();
  }

  Future<void> startTest() async {
    if (_running) return;
    _running = true;
    _error = null;
    _progress = "latency";
    notifyListeners();
    try {
      await refreshDetails();
      final latencies = <int>[];
      var failedSamples = 0;
      for (var sample = 0; sample < latencySamples; sample++) {
        try {
          latencies.add(await transport.measureLatency());
        } catch (_) {
          failedSamples++;
        }
      }
      if (latencies.isEmpty) throw SocketException("No latency samples");

      _progress = "download";
      notifyListeners();
      final downloadMbps = await transport.measureDownload(downloadBytes);
      _progress = "upload";
      notifyListeners();
      final uploadMbps = await transport.measureUpload(uploadBytes);

      final averageLatency =
          latencies.reduce((a, b) => a + b) / latencies.length;
      var jitter = 0.0;
      for (var index = 1; index < latencies.length; index++) {
        jitter += (latencies[index] - latencies[index - 1]).abs();
      }
      if (latencies.length > 1) jitter /= latencies.length - 1;

      _lastResult = NetworkDiagnosticsResult(
        downloadMbps: downloadMbps,
        uploadMbps: uploadMbps,
        minimumLatency: latencies.reduce((a, b) => a < b ? a : b).toDouble(),
        averageLatency: averageLatency,
        maximumLatency: latencies.reduce((a, b) => a > b ? a : b).toDouble(),
        packetLoss: failedSamples * 100 / latencySamples,
        jitter: jitter,
        timestamp: now(),
        server: networkDiagnosticsServer,
      );
      _progress = null;
    } catch (_) {
      _error = "failed";
      _progress = null;
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}
