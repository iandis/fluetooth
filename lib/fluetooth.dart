
import 'dart:async';

import 'package:flutter/services.dart';

class Fluetooth {
  static const MethodChannel _channel = MethodChannel('fluetooth');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
