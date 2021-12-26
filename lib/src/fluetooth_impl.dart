import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'fluetooth.dart';
import 'fluetooth_device.dart';

class FluetoothImpl implements Fluetooth {
  factory FluetoothImpl() => _instance;

  const FluetoothImpl._();

  static const FluetoothImpl _instance = FluetoothImpl._();

  static const MethodChannel _channel = MethodChannel('fluetooth/main');

  @override
  Future<FluetoothDevice> connect(String deviceAddress) async {
    final Map<Object?, Object?>? device = await _channel
        .invokeMethod<Map<Object?, Object?>>('connect', deviceAddress);

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
  Future<List<FluetoothDevice>> getPairedDevices() async {
    final List<Map<Object?, Object?>>? pairedDevices = await _channel
        .invokeListMethod<Map<Object?, Object?>>('getPairedDevices');

    if (pairedDevices != null) {
      return pairedDevices.map<FluetoothDevice>((Map<Object?, Object?> map) {
        return FluetoothDevice.fromMap(Map<String, String>.from(map));
      }).toList(growable: false);
    }
    return const <FluetoothDevice>[];
  }

  @override
  Future<bool?> get isAvailable {
    return _channel.invokeMethod<bool?>('isAvailable');
  }

  @override
  Future<bool> get isConnected async {
    return await _channel.invokeMethod<bool>('isAvailable') ?? false;
  }

  @override
  Future<void> sendBytes(List<int> bytes) {
    final Map<String, dynamic> arguments = <String, dynamic>{
      'bytes': bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
    };
    return _channel.invokeMethod<bool>('sendBytes', arguments);
  }
}
