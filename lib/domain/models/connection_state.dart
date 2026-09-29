enum DeviceConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  connectionFailed;

  bool get isConnected => this == DeviceConnectionState.connected;
  bool get isTransitioning =>
      this == DeviceConnectionState.connecting ||
      this == DeviceConnectionState.reconnecting;
  bool get isDisconnected =>
      this == DeviceConnectionState.disconnected ||
      this == DeviceConnectionState.connectionFailed;

  String get displayName {
    switch (this) {
      case DeviceConnectionState.disconnected:
        return 'Device Disconnected';
      case DeviceConnectionState.connecting:
        return 'Connecting...';
      case DeviceConnectionState.connected:
        return 'Connected';
      case DeviceConnectionState.reconnecting:
        return 'Reconnecting...';
      case DeviceConnectionState.connectionFailed:
        return 'Connection Failed';
    }
  }
}
