import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/connection_state.dart';
import '../../domain/models/device_log_entry.dart';
import '../../domain/models/device_telemetry.dart';
import '../../infrastructure/device/device_service.dart';
import '../../infrastructure/device/mock/mock_device_service.dart';

/// Provider for the singleton DeviceService
final deviceServiceProvider = Provider<DeviceService>((ref) {
  final service = MockDeviceService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream of real-time telemetry (20 Hz)
final telemetryStreamProvider = StreamProvider<DeviceTelemetry>((ref) {
  final deviceService = ref.watch(deviceServiceProvider);
  return deviceService.telemetryStream;
});

/// Stream of device connection states
final connectionStateStreamProvider =
    StreamProvider<DeviceConnectionState>((ref) {
  final deviceService = ref.watch(deviceServiceProvider);
  return deviceService.connectionStateStream;
});

/// Rolling buffer of recent EMG samples for real-time waveform chart
class EmgHistoryNotifier extends StateNotifier<List<double>> {
  final Ref ref;
  StreamSubscription<DeviceTelemetry>? _subscription;

  EmgHistoryNotifier(this.ref)
      : super(List.filled(AppConstants.emgGraphWindowSamples, 50.0)) {
    final deviceService = ref.read(deviceServiceProvider);
    _subscription = deviceService.telemetryStream.listen((telemetry) {
      if (!mounted) return;
      final updated = List<double>.from(state);
      if (updated.length >= AppConstants.emgGraphWindowSamples) {
        updated.removeAt(0);
      }
      updated.add(telemetry.emgValue);
      state = updated;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final emgHistoryProvider =
    StateNotifierProvider<EmgHistoryNotifier, List<double>>((ref) {
  return EmgHistoryNotifier(ref);
});

/// Rolling buffer of recent device logs
class DeviceLogsNotifier extends StateNotifier<List<DeviceLogEntry>> {
  final Ref ref;
  StreamSubscription<DeviceLogEntry>? _subscription;

  DeviceLogsNotifier(this.ref) : super([]) {
    final deviceService = ref.read(deviceServiceProvider);
    _subscription = deviceService.logStream.listen((entry) {
      if (!mounted) return;
      final updated = [entry, ...state];
      if (updated.length > 100) {
        updated.removeLast();
      }
      state = updated;
    });
  }

  void clear() {
    state = [];
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final deviceLogsProvider =
    StateNotifierProvider<DeviceLogsNotifier, List<DeviceLogEntry>>((ref) {
  return DeviceLogsNotifier(ref);
});
