import 'package:flauncher/providers/network_diagnostics_service.dart';

class FakeNetworkDiagnosticsTransport implements NetworkDiagnosticsTransport {
  var latencyIndex = 0;
  final latencies = [10, 15, 20, 15, 15];

  @override
  Future<int> measureLatency() async => latencies[latencyIndex++];

  @override
  Future<double> measureDownload(int bytes) async => 80;

  @override
  Future<double> measureUpload(int bytes) async => 10;
}
