enum HandState {
  open,
  opening,
  holding,
  closing,
  closed,
  stopped,
  calibrating;

  bool get isMoving => this == HandState.opening || this == HandState.closing;
  bool get isStationary => !isMoving;

  String get displayName {
    switch (this) {
      case HandState.open:
        return 'OPEN';
      case HandState.opening:
        return 'OPENING';
      case HandState.holding:
        return 'HOLDING';
      case HandState.closing:
        return 'CLOSING';
      case HandState.closed:
        return 'CLOSED';
      case HandState.stopped:
        return 'STOPPED';
      case HandState.calibrating:
        return 'CALIBRATING';
    }
  }

  static HandState fromString(String value) {
    switch (value.toUpperCase()) {
      case 'OPEN':
        return HandState.open;
      case 'OPENING':
        return HandState.opening;
      case 'HOLDING':
        return HandState.holding;
      case 'CLOSING':
        return HandState.closing;
      case 'CLOSED':
        return HandState.closed;
      case 'STOPPED':
        return HandState.stopped;
      case 'CALIBRATING':
        return HandState.calibrating;
      default:
        return HandState.holding;
    }
  }
}
