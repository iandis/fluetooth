import 'fluetooth_device.dart';
import 'fluetooth_impl.dart' if (dart.library.html) 'fluetooth_unimpl.dart';

abstract class Fluetooth {
  factory Fluetooth() = FluetoothImpl;

  Future<FluetoothDevice> connect(String deviceId);

  /// Since both Android and iOS have different flow of getting
  /// BT devices, these separated sections will describe briefly of
  /// what happens when using [getAvailableDevices] on each platforms.
  /// 
  /// ### Android
  /// The simplest flow out of the two platforms. This simply performs:
  /// - calls `BluetoothAdapter.getBondedDevices`,
  /// - converts the result into a [Map],
  /// - then converted into a list of [FluetoothDevice]s.
  /// 
  /// ### iOS
  /// A bit more flow on this one. This performs:
  /// - calls `CBCentralManager.scanForPeripherals`, 
  /// - stores every discovered peripherals into an array,
  /// - calls `CBCentralManager.stopScan` after 1 second of scanning,
  /// - converts the result into a [Map],
  /// - then converted into a list of [FluetoothDevice]s
  Future<List<FluetoothDevice>> getAvailableDevices();

  Future<bool> get isConnected;

  /// Checks if Bluetooth is available on the device.
  /// 
  /// Returns
  /// * `true` if available
  /// * `false` if not available/unsupported/unauthorized
  Future<bool> get isAvailable;

  Future<FluetoothDevice?> get connectedDevice;

  Future<void> sendBytes(List<int> bytes);

  Future<void> disconnect();
}
