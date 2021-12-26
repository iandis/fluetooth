import 'fluetooth_device.dart';
import 'fluetooth_impl.dart' if (dart.library.html) 'fluetooth_unimpl.dart';

abstract class Fluetooth {
  factory Fluetooth() = FluetoothImpl;

  Future<FluetoothDevice> connect(String deviceAddress);

  Future<List<FluetoothDevice>> getPairedDevices();

  Future<bool> get isConnected;

  /// Checks if Bluetooth is available on the device.
  /// 
  /// Returns
  /// * `true` if available
  /// * `false` if not available
  /// * `null` if not supported
  Future<bool?> get isAvailable;

  Future<FluetoothDevice?> get connectedDevice;

  Future<void> sendBytes(List<int> bytes);

  Future<void> disconnect();
}
