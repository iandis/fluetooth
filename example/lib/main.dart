import 'dart:async';
import 'package:esc_pos_gen/esc_pos_gen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'package:fluetooth/fluetooth.dart';

class MultiPosComponents implements PosComponent {
  const MultiPosComponents(this.components);
  final List<PosComponent> components;

  @override
  List<int> generate(Generator generator) {
    final List<int> bytes = <int>[];
    for (final PosComponent component in components) {
      bytes.addAll(component.generate(generator));
    }
    return bytes;
  }
}

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

  bool _isBusy = false;
  List<FluetoothDevice>? _devices;
  FluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    CapabilityProfile.load().then(_profileCompleter.complete);
    _refreshPrinters();
  }

  @override
  void dispose() {
    Fluetooth().disconnect();
    super.dispose();
  }

  Future<void> _refreshPrinters() async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    final List<FluetoothDevice> devices = await Fluetooth().getAvailableDevices();
    setState(() {
      _devices = devices;
      _isBusy = false;
    });
  }

  Future<void> _connect(FluetoothDevice device) async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    final FluetoothDevice connectedDevice = await Fluetooth().connect(
      device.id,
    );

    setState(() {
      _isBusy = false;
      _connectedDevice = connectedDevice;
    });
  }

  Future<void> _disconnect() async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    await Fluetooth().disconnect();
    setState(() {
      _isBusy = false;
      _connectedDevice = null;
    });
  }

  Future<void> _print() async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
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
      PosListComponent.builder(
        count: 20,
        builder: (int i) {
          return PosListComponent(
            <PosComponent>[
              PosRow.leftRightText(
                leftText: 'Product $i',
                leftTextStyles: const PosStyles.defaults(),
                rightText: 'Rp. $i',
              ),
              PosRow.leftRightText(
                leftText: '1 x Rp. $i',
                leftTextStyles: const PosStyles.defaults(
                  fontType: PosFontType.fontB,
                ),
                rightText: 'Rp. $i',
                rightTextStyles: const PosStyles.defaults(
                  align: PosAlign.right,
                  fontType: PosFontType.fontB,
                ),
              ),
            ],
          );
        },
      ),
      const PosSeparator(),
      PosBarcode.code128('{A12345'.split('')),
      const PosSeparator(),
      const PosFeed(1),
      const PosCut(),
    ];

    final Paper paper = Paper(
      generator: generator,
      components: components,
    );

    await Fluetooth().sendBytes(paper.bytes);
    setState(() => _isBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          TextButton(
            onPressed: _connectedDevice != null && !_isBusy ? _print : null,
            style: TextButton.styleFrom(
              primary: Colors.amber,
            ),
            child: const Text('Print'),
          ),
          IconButton(
            onPressed: _refreshPrinters,
            color: Colors.amber,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _devices == null || _devices!.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemBuilder: (_, int index) {
                final FluetoothDevice currentDevice = _devices![index];
                return ListTile(
                  title: Text(currentDevice.name),
                  subtitle: Text(currentDevice.id),
                  trailing: ElevatedButton(
                    onPressed:
                        _connectedDevice == currentDevice
                            ? _disconnect
                            : _connectedDevice == null && !_isBusy
                                ? () => _connect(currentDevice)
                                : null,
                    child: Text(
                      _connectedDevice == currentDevice
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
