package app.iandis.fluetooth

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.os.Handler
import android.os.Looper
import java.io.OutputStream
import java.lang.Exception
import java.util.*

class FluetoothManager(private val context: Context) {

    // Standard SerialPortService ID
    private val _uuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val _adapter: BluetoothAdapter?
    private var _connectedDevice: BluetoothDevice? = null
    private var _socket: BluetoothSocket? = null
    private var _outputStream: OutputStream? = null

    init {
        val bluetoothManager: BluetoothManager? =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?

        _adapter = bluetoothManager?.adapter
    }

    /**
     * @return **true** when enabled, **false** when disabled, **null** when not supported
     * */
    val isAvailable: Boolean? get() = _adapter?.isEnabled

    val isConnected: Boolean
        get() {
            if (_socket != null) {
                return _socket!!.isConnected
            }
            return false;
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
        val devicesMap: MutableList<Map<String, String>> = mutableListOf(mutableMapOf())
        val bondedDevices: Set<BluetoothDevice> = _adapter!!.bondedDevices
        if (bondedDevices.isNotEmpty()) {
            for (device: BluetoothDevice in bondedDevices) {
                val deviceMap: MutableMap<String, String> = mutableMapOf()
                deviceMap["name"] = device.name
                deviceMap["address"] = device.address
            }
        }
        return devicesMap
    }

    fun writeBytes(bytes: ByteArray) {
        if (_outputStream == null) {
            throw Exception("No device connected!")
        }
        Handler(Looper.getMainLooper()).post {
            _outputStream!!.write(bytes)
        }
    }

    fun flush() {
        if (_outputStream == null) {
            throw Exception("No device connected!")
        }
        Handler(Looper.getMainLooper()).post {
            _outputStream!!.flush()
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
        if (_connectedDevice != null) {
            _socket = _connectedDevice!!.createRfcommSocketToServiceRecord(_uuid)
            _socket!!.connect()
        }
    }

    fun disconnect() {
        if (_socket != null) {
            _socket!!.close()
            _outputStream?.close()
            _socket = null
            _outputStream = null
            _connectedDevice = null
        }
    }
}