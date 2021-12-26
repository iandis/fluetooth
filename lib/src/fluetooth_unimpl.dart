import 'fluetooth_device.dart';
import 'fluetooth.dart';

class FluetoothImpl implements Fluetooth {
  factory FluetoothImpl() => _instance;

  const FluetoothImpl._();

  static const FluetoothImpl _instance = FluetoothImpl._();

  @override
  Future<FluetoothDevice> connect(String deviceAddress) {
    throw UnsupportedError('Fluetooth is not supported on this platform');
  }

  @override
  Future<FluetoothDevice?> get connectedDevice {
    throw UnsupportedError('Fluetooth is not supported on this platform');
  }

  @override
  Future<void> disconnect() {
    throw UnsupportedError('Fluetooth is not supported on this platform');
  }

  @override
  Future<List<FluetoothDevice>> getPairedDevices() {
    throw UnsupportedError('Fluetooth is not supported on this platform');
  }

  @override
  Future<bool?> get isAvailable {
    throw UnsupportedError('Fluetooth is not supported on this platform');
  }

  @override
  Future<bool> get isConnected {
    throw UnsupportedError('Fluetooth is not supported on this platform');
  }

  @override
  Future<void> sendBytes(List<int> bytes) {
    throw UnsupportedError('Fluetooth is not supported on this platform');
  }
}
