package app.iandis.fluetooth

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.os.Handler
import android.os.Looper
import java.io.OutputStream
import java.lang.Exception
import java.util.*

class FluetoothManager(private val _adapter: BluetoothAdapter?) {

    // Standard SerialPortService ID
    private val _uuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private var _connectedDevice: BluetoothDevice? = null
    private var _socket: BluetoothSocket? = null
    private val _outputStream: OutputStream? get() = _socket?.outputStream

    /**
     * @return **true** when enabled, **false** when disabled, **null** when not supported
     * */
    val isAvailable: Boolean? get() = _adapter?.isEnabled

    val isConnected: Boolean
        get() {
            if (_socket != null) {
                return _socket!!.isConnected
            }
            return false
        }

    val connectedDevice: Map<String, String>?
        get() {
            if (_connectedDevice == null) {
                return null
            }
            val deviceMap: MutableMap<String, String> = mutableMapOf()
            deviceMap["name"] = _connectedDevice!!.name
            deviceMap["address"] = _connectedDevice!!.address
            return deviceMap
        }

    fun getPairedDevices(): List<Map<String, String>> {
        val devicesMap: MutableList<Map<String, String>> = mutableListOf()
        val bondedDevices: Set<BluetoothDevice> = _adapter!!.bondedDevices
        if (bondedDevices.isNotEmpty()) {
            for (device: BluetoothDevice in bondedDevices) {
                val deviceMap: MutableMap<String, String> = mutableMapOf()
                deviceMap["name"] = device.name
                deviceMap["address"] = device.address
                devicesMap.add(deviceMap)
            }
        }
        return devicesMap
    }

    private fun _writeBytes(bytes: ByteArray) {
        if (_outputStream == null) {
            throw Exception("No device connected!")
        }
        _outputStream!!.write(bytes)
    }

    private fun _flush() {
        if (_outputStream == null) {
            throw Exception("No device connected!")
        }
        _outputStream!!.flush()
    }

    fun send(bytes: ByteArray) {
        Handler(Looper.getMainLooper()).post {
            _writeBytes(bytes)
            _flush()
        }
    }

    fun connect(deviceAddress: String) {
        disconnect()

        val bondedDevices: Set<BluetoothDevice> = _adapter!!.bondedDevices
        if (bondedDevices.isNotEmpty()) {
            for (device: BluetoothDevice in bondedDevices) {
                if (device.address.equals(deviceAddress)) {
                    _connectedDevice = device
                    break
                }
            }
        }
        try {
            if (_connectedDevice != null) {
                _socket = _connectedDevice!!.createRfcommSocketToServiceRecord(_uuid)
                _socket!!.connect()
            }
        } catch (_: Exception) {
            _connectedDevice = null
            if (_socket != null) {
                _outputStream?.close()
                _socket!!.close()
                _socket = null
            }
        }
    }

    fun disconnect() {
        if (_socket != null) {
            _outputStream?.close()
            _socket!!.close()
            _socket = null
            _connectedDevice = null
        }
    }
}