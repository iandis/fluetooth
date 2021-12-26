class FluetoothDevice {
  const FluetoothDevice({
    required this.name,
    required this.address,
  });

  final String name;
  final String address;

  factory FluetoothDevice.fromMap(Map<String, dynamic> map) {
    return FluetoothDevice(
      name: map['name'] as String,
      address: map['address'] as String,
    );
  }
}
