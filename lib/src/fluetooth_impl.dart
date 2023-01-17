import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'fluetooth.dart';
import 'fluetooth_device.dart';

class FluetoothImpl implements Fluetooth {
  factory FluetoothImpl() => _instance;

  const FluetoothImpl._();

  static const FluetoothImpl _instance = FluetoothImpl._();

  static const MethodChannel _channel = MethodChannel('fluetooth/main');

  static Future<bool> _requestBluetoothConnectPermission() async {
    if (!Platform.isAndroid) return true;
    bool isGranted = await Permission.bluetoothConnect.isGranted;
    if (!isGranted) {
      isGranted = await Permission.bluetoothConnect.request().isGranted;
    }
    return isGranted;
  }

  @override
  Future<FluetoothDevice> connect(String deviceId) async {
    final Map<Object?, Object?>? device =
        await _channel.invokeMethod<Map<Object?, Object?>>('connect', deviceId);

    return FluetoothDevice.fromMap(Map<String, String>.from(device!));
  }

  @override
  Future<FluetoothDevice?> get connectedDevice async {
    final Map<Object?, Object?>? responseMap =
        await _channel.invokeMapMethod<Object?, Object?>('connectedDevice');

    if (responseMap != null) {
      return FluetoothDevice.fromMap(Map<String, String>.from(responseMap));
    }
  }

  @override
  Future<void> disconnect() {
    return _channel.invokeMethod<bool>('disconnect');
  }

  @override
  Future<List<FluetoothDevice>> getAvailableDevices() async {
    if (!await _requestBluetoothConnectPermission()) {
      return const <FluetoothDevice>[];
    }
    final List<Map<Object?, Object?>>? availableDevices = await _channel
        .invokeListMethod<Map<Object?, Object?>>('getAvailableDevices');

    if (availableDevices != null) {
      return availableDevices.map<FluetoothDevice>((Map<Object?, Object?> map) {
        return FluetoothDevice.fromMap(Map<String, String>.from(map));
      }).toList(growable: false);
    }
    return const <FluetoothDevice>[];
  }

  @override
  Future<bool> get isAvailable async {
    return await _channel.invokeMethod<bool>('isAvailable') ?? false;
  }

  @override
  Future<bool> get isConnected async {
    return await _channel.invokeMethod<bool>('isConnected') ?? false;
  }

  @override
  Future<void> sendBytes(List<int> bytes) {
    final Map<String, dynamic> arguments = <String, dynamic>{
      'bytes': bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
    };
    return _channel.invokeMethod<bool>('sendBytes', arguments);
  }
}
