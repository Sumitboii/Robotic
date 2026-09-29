import '../../../core/constants/app_constants.dart';
import '../../../domain/models/hand_state.dart';

/// Simulated physical prosthetic hand mechanics and kinematics.
/// Models motor actuator, finger linkages, angular limits, and continuous motion.
class SimulatedProstheticHand {
  double _currentAngle;
  double _targetAngle;
  double _minAngle;
  double _maxAngle;
  final double _speedDegPerSec;
  HandState _state;

  SimulatedProstheticHand({
    double initialAngle = 45.0,
    double minAngle = AppConstants.defaultMinAngle,
    double maxAngle = AppConstants.defaultMaxAngle,
    double speedDegPerSec = AppConstants.defaultMovementSpeedDegPerSec,
  })  : _currentAngle = initialAngle.clamp(minAngle, maxAngle),
        _targetAngle = initialAngle.clamp(minAngle, maxAngle),
        _minAngle = minAngle,
        _maxAngle = maxAngle,
        _speedDegPerSec = speedDegPerSec,
        _state = HandState.holding;

  double get currentAngle => _currentAngle;
  double get targetAngle => _targetAngle;
  double get minAngle => _minAngle;
  double get maxAngle => _maxAngle;
  double get speedDegPerSec => _speedDegPerSec;
  HandState get state => _state;
  bool get isMoving =>
      _state == HandState.opening || _state == HandState.closing;

  /// Progress ratio from 0.0 (fully open) to 1.0 (fully closed)
  double get closureRatio {
    final range = _maxAngle - _minAngle;
    if (range <= 0.0) return 0.0;
    return ((_currentAngle - _minAngle) / range).clamp(0.0, 1.0);
  }

  /// Update active limits (from calibration or settings)
  void updateLimits({required double minAngle, required double maxAngle}) {
    if (minAngle >= maxAngle) return;
    _minAngle = minAngle;
    _maxAngle = maxAngle;
    _currentAngle = _currentAngle.clamp(_minAngle, _maxAngle);
    _targetAngle = _targetAngle.clamp(_minAngle, _maxAngle);
  }

  /// Initiate smooth opening movement towards minAngle
  void open() {
    _targetAngle = _minAngle;
    if ((_currentAngle - _minAngle).abs() < 0.1) {
      _currentAngle = _minAngle;
      _state = HandState.open;
    } else {
      _state = HandState.opening;
    }
  }

  /// Initiate smooth closing movement towards maxAngle
  void close() {
    _targetAngle = _maxAngle;
    if ((_maxAngle - _currentAngle).abs() < 0.1) {
      _currentAngle = _maxAngle;
      _state = HandState.closed;
    } else {
      _state = HandState.closing;
    }
  }

  /// Emergency / manual immediate stop. Halts motor immediately.
  void stop() {
    _targetAngle = _currentAngle;
    _state = HandState.stopped;
  }

  /// Move towards specific angle during calibration
  void moveToAngle(double angle) {
    final clamped = angle.clamp(
        AppConstants.absoluteMinAngle, AppConstants.absoluteMaxAngle);
    _targetAngle = clamped;
    if (clamped < _currentAngle) {
      _state = HandState.opening;
    } else if (clamped > _currentAngle) {
      _state = HandState.closing;
    } else {
      _state = HandState.holding;
    }
  }

  /// Physics step integration called by simulated micro-controller loop
  void step(double dtSeconds) {
    if (_state != HandState.opening && _state != HandState.closing) {
      return;
    }

    final maxStep = _speedDegPerSec * dtSeconds;
    final diff = _targetAngle - _currentAngle;

    if (diff.abs() <= maxStep) {
      // Reached target
      _currentAngle = _targetAngle;
      if ((_currentAngle - _minAngle).abs() < 0.2) {
        _state = HandState.open;
      } else if ((_currentAngle - _maxAngle).abs() < 0.2) {
        _state = HandState.closed;
      } else {
        _state = HandState.holding;
      }
    } else {
      // Step towards target
      if (diff > 0) {
        _currentAngle += maxStep;
        _state = HandState.closing;
      } else {
        _currentAngle -= maxStep;
        _state = HandState.opening;
      }
      _currentAngle = _currentAngle.clamp(
        AppConstants.absoluteMinAngle,
        AppConstants.absoluteMaxAngle,
      );
    }
  }

  /// Reset to initial default state
  void reset() {
    _minAngle = AppConstants.defaultMinAngle;
    _maxAngle = AppConstants.defaultMaxAngle;
    _currentAngle = 45.0;
    _targetAngle = 45.0;
    _state = HandState.holding;
  }
}
