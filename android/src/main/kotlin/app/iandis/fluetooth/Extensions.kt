package app.iandis.fluetooth

import android.bluetooth.BluetoothDevice

fun BluetoothDevice.toMap(): Map<String, String> {
    val deviceMap: MutableMap<String, String> = mutableMapOf()
    deviceMap["name"] = this.name
    deviceMap["address"] = this.address
    return deviceMap
}