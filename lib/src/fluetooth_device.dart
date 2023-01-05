class FluetoothDevice {
  const FluetoothDevice({
    required this.id,
    required this.name,
  });

  /// Both Android and iOS have different forms of [id] :
  /// - a MAC Address on Android.
  /// - a UUID on iOS.
  final String id;

  /// The name of this Bluetooth device.
  /// 
  /// Note that on iOS, [name] can be empty
  final String name;

  factory FluetoothDevice.fromMap(Map<String, dynamic> map) {
    return FluetoothDevice(
      id: map['id'] as String,
      name: map['name'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is FluetoothDevice &&
      other.id == id &&
      other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}
