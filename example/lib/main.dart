import 'dart:async';
import 'package:esc_pos_gen/esc_pos_gen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'package:fluetooth/fluetooth.dart';

void main() {
  runApp(
    const MaterialApp(
      home: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Completer<CapabilityProfile> _profileCompleter =
      Completer<CapabilityProfile>();

  List<FluetoothDevice>? _devices;
  FluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    CapabilityProfile.load().then(_profileCompleter.complete);
    Fluetooth().getPairedDevices().then(
      (List<FluetoothDevice> devices) {
        setState(() => _devices = devices);
      },
    );
  }

  Future<void> _print() async {
    final CapabilityProfile profile = await _profileCompleter.future;
    final Generator generator = Generator(PaperSize.mm58, profile);
    final ByteData logoBytes = await rootBundle.load('assets/amd_logo.jpg');
    final img.Image? decodedImg = await compute(
      img.decodeJpg,
      logoBytes.buffer.asUint8List(),
    );
    final img.Image resizedImg = img.copyResize(
      decodedImg!,
      width: 80,
    );

    final List<PosComponent> components = <PosComponent>[
      PosImage(image: resizedImg),
      const PosText.center('My Store'),
      const PosSeparator(),
      for (int i = 1; i <= 20; i++)
        PosRow.leftRightText(
          leftText: 'Product $i',
          rightText: 'Rp. $i',
        ),
      const PosSeparator(),
      PosBarcode.code128(
        '{A12345'.split(''),
      ),
      const PosSeparator(),
      const PosFeed(1),
      const PosCut(),
    ];

    final Paper paper = Paper(
      generator: generator,
      components: components,
    );

    Fluetooth().sendBytes(paper.bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          ElevatedButton(
            onPressed: _connectedDevice != null ? _print : null,
            child: const Text('Print'),
          ),
        ],
      ),
      body: _devices == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemBuilder: (_, int index) {
                final FluetoothDevice currentDevice = _devices![index];
                return ListTile(
                  title: Text(currentDevice.name),
                  subtitle: Text(currentDevice.address),
                  trailing: ElevatedButton(
                    onPressed: _connectedDevice?.address ==
                            currentDevice.address
                        ? () {
                            Fluetooth().disconnect();
                            setState(() => _connectedDevice = null);
                          }
                        : _connectedDevice == null
                            ? () {
                                Fluetooth().connect(currentDevice.address).then(
                                  (FluetoothDevice device) {
                                    setState(() {
                                      _connectedDevice = device;
                                    });
                                  },
                                );
                              }
                            : null,
                    child: Text(
                      _connectedDevice?.address == currentDevice.address
                          ? 'Disconnect'
                          : 'Connect',
                    ),
                  ),
                );
              },
              itemCount: _devices!.length,
            ),
    );
  }
}
