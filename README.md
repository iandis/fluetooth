A Flutter library for sending bytes to Bluetooth devices. Available on Android and iOS.

## Android Setup
This library is only compatible for Android SDK 21+, so we need this in **android/app/build.gradle**
```
Android {
  defaultConfig {
     minSdkVersion 21
```
## iOS Setup
This library needs Bluetooth permissions on iOS, so we need this in **ios/Runner/Info.plist**
```
...
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Need BLE permission for connecting to BLE devices</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Need BLE permission for retrieving BLE devices info</string>
...
```
# Examples
We'll need [esc_pos_gen](https://pub.dev/packages/esc_pos_gen) for this example.

First prepare a bill to be printed.
```dart
...
final List<PosComponent> components = <PosComponent>[
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
            rightText: 'USD $i',
            ),
            PosRow.leftRightText(
            leftText: '1 x USD $i',
            leftTextStyles: const PosStyles.defaults(
                fontType: PosFontType.fontB,
            ),
            rightText: 'USD $i',
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
...
```

Retrieve available bluetooth devices.
```dart
final List<FluetoothDevice> devices = await Fluetooth().getAvailableDevices();
```

Connect to a printer.
```dart
...
final FluetoothDevice printer = devices.first;
await Fluetooth().connect(printer.id);
```

Prints the bill to the printer
```dart
...
await Fluetooth().sendBytes(paper.bytes);
...
```