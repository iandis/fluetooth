package app.iandis.fluetooth

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import java.io.OutputStream
import java.lang.Exception
import java.util.UUID
import java.util.concurrent.Executor
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class FluetoothManager(private val _adapter: BluetoothAdapter?) {

    // Standard SerialPortService ID
    private val _uuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private var _connectedDevice: BluetoothDevice? = null
    private var _socket: BluetoothSocket? = null
    private var _outputStream: OutputStream? = null
    private val _executorService: ExecutorService = Executors.newSingleThreadExecutor()
    private val _executor: Executor = SerialExecutor(_executorService)

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
        get() = _connectedDevice?.toMap()

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

    fun send(bytes: ByteArray, onComplete: () -> Unit) {
        _executor.execute {
            _writeBytes(bytes)
            _flush()
            onComplete()
        }
    }

    @Synchronized
    fun connect(deviceAddress: String, onResult: (BluetoothDevice?) -> Unit) {
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

        _executor.execute {
            try {
                if (_connectedDevice != null) {
                    _socket = _connectedDevice!!.createRfcommSocketToServiceRecord(_uuid)
                    _socket!!.connect()
                    _outputStream = _socket!!.outputStream
                }
            } catch (_: Exception) {
                _connectedDevice = null
                if (_socket != null) {
                    _outputStream?.close()
                    _outputStream = null
                    _socket!!.close()
                    _socket = null
                }
            }

            onResult(_connectedDevice)
        }
    }

    fun disconnect() {
        if (_socket != null) {
            _outputStream?.close()
            _outputStream = null
            _socket!!.close()
            _socket = null
            _connectedDevice = null
        }
    }

    fun dispose() {
        disconnect()
        _executorService.shutdown()
    }
}