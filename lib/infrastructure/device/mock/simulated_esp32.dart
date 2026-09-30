import 'dart:async';
import 'dart:math' as math;
import '../../../core/constants/app_constants.dart';
import '../../../domain/models/connection_state.dart';
import '../../../domain/models/device_command.dart';
import '../../../domain/models/device_log_entry.dart';
import '../../../domain/models/device_settings.dart';
import '../../../domain/models/device_telemetry.dart';
import '../../../domain/models/hand_state.dart';
import '../../../domain/models/operating_mode.dart';
import '../../../domain/models/wire_protocol.dart';
import 'simulated_prosthetic_hand.dart';

/// Simulated ESP32 Embedded Microcontroller (Assignment §4).
/// Emulates hardware timers, ADC sampling (EMG), power management (Battery),
/// motor PWM control (Prosthetic Hand), mode state machines, and raw serial wire protocol streams.
class SimulatedEsp32 {
  final SimulatedProstheticHand _hand;
  final math.Random _random = math.Random();

  // Configuration
  String _deviceName;
  double _batteryPercentage;
  double _emgThreshold;
  double _batteryWarningThreshold;
  OperatingMode _mode;

  // Real-time state
  DeviceConnectionState _connectionState = DeviceConnectionState.connected;
  double _currentEmg = 50.0;
  double _emgPhase = 0.0;
  double _emgSpikeIntensity = 0.0;
  bool _emgArmed = true;
  bool _emgToggleStateClose =
      true; // next contraction will close if true, open if false

  // Error simulation states (§10)
  bool _emgSensorFault = false;
  bool _failNextReconnect = false;

  // Auto mode timer & state
  double _autoModeHoldTimer = 0.0;
  bool _autoTargetOpen = true;

  // Loop timer & log throttling
  Timer? _simulationTimer;
  DateTime _lastTickTime = DateTime.now();
  DateTime _lastRxLogTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Streams
  final StreamController<String> _rawTelemetryController =
      StreamController<String>.broadcast();
  final StreamController<DeviceTelemetry> _telemetryController =
      StreamController<DeviceTelemetry>.broadcast();
  final StreamController<DeviceConnectionState> _connectionController =
      StreamController<DeviceConnectionState>.broadcast();
  final StreamController<DeviceLogEntry> _logController =
      StreamController<DeviceLogEntry>.broadcast();

  SimulatedEsp32({
    DeviceSettings? initialSettings,
    double initialBattery = AppConstants.initialBatteryPercentage,
  })  : _deviceName =
            initialSettings?.deviceName ?? AppConstants.defaultDeviceName,
        _batteryPercentage = initialBattery,
        _emgThreshold =
            initialSettings?.emgThreshold ?? AppConstants.defaultEmgThreshold,
        _batteryWarningThreshold = initialSettings?.batteryWarningThreshold ??
            AppConstants.defaultBatteryWarningThreshold,
        _mode = initialSettings?.defaultOperatingMode ?? OperatingMode.auto,
        _hand = SimulatedProstheticHand(
          initialAngle: 45.0,
          minAngle: initialSettings?.minAngle ?? AppConstants.defaultMinAngle,
          maxAngle: initialSettings?.maxAngle ?? AppConstants.defaultMaxAngle,
        ) {
    _startSimulationLoop();
    _log(DeviceLogEntry.info(
        'Simulated ESP32 firmware initialized. Device: $_deviceName'));
  }

  // Getters
  Stream<String> get rawTelemetryStream => _rawTelemetryController.stream;
  Stream<DeviceTelemetry> get telemetryStream => _telemetryController.stream;
  Stream<DeviceConnectionState> get connectionStateStream =>
      _connectionController.stream;
  Stream<DeviceLogEntry> get logStream => _logController.stream;
  DeviceConnectionState get connectionState => _connectionState;
  SimulatedProstheticHand get hand => _hand;
  double get batteryPercentage => _batteryPercentage;
  OperatingMode get operatingMode => _mode;
  String get deviceName => _deviceName;
  double get currentEmg => _currentEmg;
  bool get isEmgArmed => _emgArmed;
  bool get isEmgSensorFaultSimulated => _emgSensorFault;
  bool get willFailNextReconnect => _failNextReconnect;

  DeviceTelemetry get currentTelemetry => DeviceTelemetry(
        deviceName: _deviceName,
        batteryPercentage: _batteryPercentage,
        positionDegrees: _hand.currentAngle,
        emgValue: _emgSensorFault ? 0.0 : _currentEmg,
        isEmgSensorAvailable: !_emgSensorFault,
        operatingMode: _mode,
        handState: _hand.state,
        minAngle: _hand.minAngle,
        maxAngle: _hand.maxAngle,
        isLowBattery: _batteryPercentage <= _batteryWarningThreshold,
        rawFrame: currentWireTelemetry,
        timestamp: DateTime.now(),
      );

  void _startSimulationLoop() {
    _simulationTimer?.cancel();
    _lastTickTime = DateTime.now();
    _simulationTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.telemetryUpdateIntervalMs),
      (_) => _onSimulationTick(),
    );
  }

  /// 20 Hz simulation cycle
  void _onSimulationTick() {
    if (_connectionState != DeviceConnectionState.connected) {
      return;
    }

    final now = DateTime.now();
    final diff = now.difference(_lastTickTime).inMicroseconds / 1000000.0;
    final dtSeconds = (diff < 0.02 || diff > 0.2) ? 0.05 : diff;
    _lastTickTime = now;

    // 1. Update hand physics
    _hand.step(dtSeconds);

    // 2. Update battery drain
    _updateBattery(dtSeconds);

    // 3. Update EMG signal synthesis (if sensor active)
    _updateEmgSignal(dtSeconds);

    // 4. Update operating mode state machines
    _updateModeLogic(dtSeconds);

    // 5. Emit raw wire frame (§4)
    final rawFrame = currentWireTelemetry;
    if (!_rawTelemetryController.isClosed) {
      _rawTelemetryController.add(rawFrame);
    }

    // 6. Direct telemetry stream broadcast
    final telemetry = currentTelemetry;
    if (!_telemetryController.isClosed) {
      _telemetryController.add(telemetry);
    }

    // 7. Throttled serial logging (~1 per second)
    if (now.difference(_lastRxLogTime).inMilliseconds >= 1000) {
      _lastRxLogTime = now;
      _log(DeviceLogEntry.info('RX $rawFrame'));
    }
  }

  /// Synthesizes continuous, physiologically plausible EMG signal with noise and contraction peaks
  void _updateEmgSignal(double dtSeconds) {
    if (_emgSensorFault) {
      _currentEmg = 0.0;
      return;
    }

    _emgPhase += dtSeconds * 3.5; // oscillation rate

    // Baseline carrier + low frequency wave + noise
    final wave = math.sin(_emgPhase) * 12.0 + math.cos(_emgPhase * 0.7) * 8.0;
    final noise = (_random.nextDouble() - 0.5) * 14.0;
    double emg = 52.0 + wave + noise;

    // Apply manual or simulated contraction burst
    if (_emgSpikeIntensity > 0.0) {
      emg += _emgSpikeIntensity;
      _emgSpikeIntensity =
          math.max(0.0, _emgSpikeIntensity - dtSeconds * 120.0);
    } else if (_mode == OperatingMode.emg && _random.nextDouble() < 0.012) {
      // Periodic automatic contraction pulse during EMG mode demo
      _emgSpikeIntensity = 130.0 + _random.nextDouble() * 50.0;
    }

    _currentEmg = emg.clamp(10.0, 250.0);

    // Hysteresis edge trigger for contraction
    final rearmThreshold = math.max(20.0, _emgThreshold - 15.0);
    if (_currentEmg < rearmThreshold) {
      _emgArmed = true;
    } else if (_currentEmg >= _emgThreshold && _emgArmed) {
      _emgArmed = false;
      _onEmgContractionDetected();
    }
  }

  void _onEmgContractionDetected() {
    _log(DeviceLogEntry.info(
      'EMG Contraction detected! (Value: ${_currentEmg.toStringAsFixed(0)} >= Threshold: $_emgThreshold)',
    ));

    if (_mode == OperatingMode.emg) {
      if (_batteryPercentage <= 0.0) {
        _log(DeviceLogEntry.warning('Cannot move: Battery depleted (0%)'));
        return;
      }

      if (_emgToggleStateClose) {
        _log(DeviceLogEntry.command('EMG Trigger: Closing hand'));
        _hand.close();
        _emgToggleStateClose = false;
      } else {
        _log(DeviceLogEntry.command('EMG Trigger: Opening hand'));
        _hand.open();
        _emgToggleStateClose = true;
      }
    }
  }

  /// Drain battery based on activity
  void _updateBattery(double dtSeconds) {
    if (_batteryPercentage <= 0.0) {
      _batteryPercentage = 0.0;
      if (_hand.isMoving) {
        _hand.stop();
        _log(DeviceLogEntry.error(
            'Battery depleted! Halting all motor activity.'));
      }
      return;
    }

    // Drain rate: ~0.08%/s when moving, ~0.008%/s when idle
    final drainRate = _hand.isMoving ? 0.08 : 0.008;
    final prevBattery = _batteryPercentage;
    _batteryPercentage =
        math.max(0.0, _batteryPercentage - drainRate * dtSeconds);

    // Check warning transition
    if (prevBattery > _batteryWarningThreshold &&
        _batteryPercentage <= _batteryWarningThreshold) {
      _log(DeviceLogEntry.warning(
        'Low battery warning! Level: ${_batteryPercentage.toStringAsFixed(1)}% <= $_batteryWarningThreshold%',
      ));
    }
  }

  /// State machine for AUTO and other modes
  void _updateModeLogic(double dtSeconds) {
    if (_batteryPercentage <= 0.0) return;

    if (_mode == OperatingMode.auto) {
      if (_hand.state == HandState.open ||
          _hand.state == HandState.closed ||
          _hand.state == HandState.holding) {
        _autoModeHoldTimer += dtSeconds;
        if (_autoModeHoldTimer >= 1.6) {
          _autoModeHoldTimer = 0.0;
          if (_autoTargetOpen) {
            _log(DeviceLogEntry.command('AUTO cycle: Moving OPEN'));
            _hand.open();
            _autoTargetOpen = false;
          } else {
            _log(DeviceLogEntry.command('AUTO cycle: Moving CLOSE'));
            _hand.close();
            _autoTargetOpen = true;
          }
        }
      }
    }
  }

  /// Canonical wire protocol serialization of current telemetry state (Assignment §4)
  String get currentWireTelemetry {
    final emgStr = _emgSensorFault
        ? 'ERR'
        : (_currentEmg == _currentEmg.roundToDouble()
            ? _currentEmg.toStringAsFixed(0)
            : _currentEmg.toStringAsFixed(1));
    final battStr = _batteryPercentage == _batteryPercentage.roundToDouble()
        ? _batteryPercentage.toStringAsFixed(0)
        : _batteryPercentage.toStringAsFixed(1);
    final posStr = _hand.currentAngle == _hand.currentAngle.roundToDouble()
        ? _hand.currentAngle.toStringAsFixed(0)
        : _hand.currentAngle.toStringAsFixed(1);

    return 'BATTERY:$battStr POSITION:$posStr EMG:$emgStr MODE:${_mode.displayName} STATE:${_hand.state.displayName}';
  }

  /// Process raw text wire protocol command (Assignment §4)
  void processWireCommand(String rawCommand) {
    final trimmed = rawCommand.trim();
    if (_connectionState != DeviceConnectionState.connected) {
      _log(
          DeviceLogEntry.warning('Command rejected: Device is not connected.'));
      return;
    }

    final command = WireProtocol.decodeCommand(trimmed);
    if (command != null) {
      processCommand(command);
    } else {
      _log(DeviceLogEntry.error('ERR:INVALID_COMMAND: $trimmed'));
    }
  }

  // Public Command Handlers
  void processCommand(DeviceCommand command) {
    if (_connectionState != DeviceConnectionState.connected) {
      _log(
          DeviceLogEntry.warning('Command rejected: Device is not connected.'));
      return;
    }

    _log(DeviceLogEntry.command('TX ${WireProtocol.encodeCommand(command)}'));

    switch (command.type) {
      case DeviceCommandType.open:
        if (_batteryPercentage <= 0.0) {
          _log(DeviceLogEntry.error('Cannot open: Battery 0%'));
          return;
        }
        _autoModeHoldTimer = 0.0;
        _hand.open();
        break;

      case DeviceCommandType.close:
        if (_batteryPercentage <= 0.0) {
          _log(DeviceLogEntry.error('Cannot close: Battery 0%'));
          return;
        }
        _autoModeHoldTimer = 0.0;
        _hand.close();
        break;

      case DeviceCommandType.stop:
        _autoModeHoldTimer = 0.0;
        _emgSpikeIntensity = 0.0;
        _hand.stop();
        if (_mode == OperatingMode.auto) {
          _mode = OperatingMode.manual;
          _log(DeviceLogEntry.info(
              'AUTO mode cancelled due to emergency STOP. Switched to MANUAL.'));
        }
        _log(DeviceLogEntry.warning(
            'EMERGENCY STOP EXECUTED. Movement halted immediately.'));
        break;

      case DeviceCommandType.calibrate:
        _mode = OperatingMode.manual;
        _autoModeHoldTimer = 0.0;
        _emgSpikeIntensity = 0.0;
        _hand.stop();
        _log(DeviceLogEntry.info('Entering calibration state.'));
        break;

      case DeviceCommandType.setMode:
        if (command.payload is OperatingMode) {
          setOperatingMode(command.payload as OperatingMode);
        }
        break;

      case DeviceCommandType.updateLimits:
        if (command.payload is Map) {
          final map = command.payload as Map;
          final min = (map['minAngle'] as num).toDouble();
          final max = (map['maxAngle'] as num).toDouble();
          _hand.updateLimits(minAngle: min, maxAngle: max);
          _log(DeviceLogEntry.info('Updated limits: min=$min°, max=$max°'));
        }
        break;

      case DeviceCommandType.resetBattery:
        _batteryPercentage = 100.0;
        _log(DeviceLogEntry.info('Battery reset to 100%'));
        break;
    }
  }

  void setOperatingMode(OperatingMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;
    _autoModeHoldTimer = 0.0;
    _emgArmed = true;
    _log(
        DeviceLogEntry.info('Operating mode changed to: ${_mode.displayName}'));

    if (_mode == OperatingMode.auto) {
      _autoTargetOpen = true;
      _hand.open();
    }
  }

  void updateSettings(DeviceSettings settings) {
    _deviceName = settings.deviceName;
    _emgThreshold = settings.emgThreshold;
    _batteryWarningThreshold = settings.batteryWarningThreshold;
    _hand.updateLimits(
        minAngle: settings.minAngle, maxAngle: settings.maxAngle);
    setOperatingMode(settings.defaultOperatingMode);
    _log(DeviceLogEntry.info('Settings applied to ESP32 firmware.'));
  }

  // Connection Simulation (§10)
  Future<void> connect() async {
    if (_connectionState == DeviceConnectionState.connected) return;

    _connectionState = DeviceConnectionState.connecting;
    _connectionController.add(_connectionState);
    _log(DeviceLogEntry.info('ESP32 connecting via BLE GATT...'));

    await Future.delayed(const Duration(milliseconds: 600));

    _connectionState = DeviceConnectionState.connected;
    _connectionController.add(_connectionState);
    _lastTickTime = DateTime.now();
    _log(DeviceLogEntry.info(
        'ESP32 connected successfully. MTU: 512, Handshake ACK.'));
  }

  Future<void> disconnect() async {
    _connectionState = DeviceConnectionState.disconnected;
    _connectionController.add(_connectionState);
    _hand.stop();
    _log(DeviceLogEntry.warning('ESP32 connection terminated.'));
  }

  Future<void> reconnect() async {
    _connectionState = DeviceConnectionState.reconnecting;
    _connectionController.add(_connectionState);
    _log(DeviceLogEntry.info('Attempting automatic BLE reconnection...'));

    await Future.delayed(const Duration(milliseconds: 600));

    if (_failNextReconnect) {
      _failNextReconnect = false;
      _connectionState = DeviceConnectionState.connectionFailed;
      _connectionController.add(_connectionState);
      _log(
          DeviceLogEntry.error('BLE Reconnection failed: Device unreachable.'));
    } else {
      _connectionState = DeviceConnectionState.connected;
      _connectionController.add(_connectionState);
      _lastTickTime = DateTime.now();
      _log(DeviceLogEntry.info('ESP32 reconnected successfully.'));
    }
  }

  // Demo & Fault Injection Helpers (§10)
  void triggerEmgSpike([double spikeValue = 160.0]) {
    if (_emgSensorFault) {
      _log(DeviceLogEntry.warning('Cannot spike EMG: Sensor is faulted'));
      return;
    }
    _emgSpikeIntensity = spikeValue;
    _log(DeviceLogEntry.info(
        'Simulated bio-signal spike triggered: +$spikeValue'));
  }

  void setBatteryPercentage(double battery) {
    _batteryPercentage = battery.clamp(0.0, 100.0);
    _log(DeviceLogEntry.warning(
        'Demo override: Battery set to ${_batteryPercentage.toStringAsFixed(0)}%'));
  }

  void setDeviceName(String name) {
    _deviceName = name;
  }

  void toggleEmgSensorFault([bool? enable]) {
    _emgSensorFault = enable ?? !_emgSensorFault;
    if (_emgSensorFault) {
      _log(DeviceLogEntry.error(
          'FAULT: EMG bio-potential sensor disconnected/offline'));
    } else {
      _log(DeviceLogEntry.info(
          'RESTORED: EMG sensor signal online and operational'));
    }
  }

  void setFailNextReconnect(bool fail) {
    _failNextReconnect = fail;
    _log(DeviceLogEntry.warning(
        'Demo setting: Next reconnect will ${fail ? 'FAIL' : 'SUCCEED'}'));
  }

  void _log(DeviceLogEntry entry) {
    if (!_logController.isClosed) {
      _logController.add(entry);
    }
  }

  void dispose() {
    _simulationTimer?.cancel();
    _rawTelemetryController.close();
    _telemetryController.close();
    _connectionController.close();
    _logController.close();
  }
}
