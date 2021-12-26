import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluetooth/fluetooth.dart';

void main() {
  const MethodChannel channel = MethodChannel('fluetooth');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return true;
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('isAvailable', () async {
    expect(await Fluetooth().isAvailable, true);
  });
}
