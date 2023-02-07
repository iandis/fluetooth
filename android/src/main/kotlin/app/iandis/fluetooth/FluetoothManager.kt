package app.iandis.fluetooth

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import java.io.OutputStream
import java.lang.Exception
import java.util.UUID

class FluetoothManager(private val _adapter: BluetoothAdapter?) {

    // Standard SerialPortService ID
    private val _uuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private var _connectedDevice: BluetoothDevice? = null
    private var _socket: BluetoothSocket? = null
    private var _outputStream: OutputStream? = null
    private val _executor: SerialExecutor = SerialExecutor()

    /**
     * @return **true** when enabled, **false** when disabled, **null** when not supported
     * */
    val isAvailable: Boolean get() = _adapter?.isEnabled ?: false

    val isConnected: Boolean
        get() = _socket?.isConnected == true

    val connectedDevice: Map<String, String>?
        get() = _connectedDevice?.toMap()

    fun getAvailableDevices(): List<Map<String, String>> {
        val devicesMap: MutableList<Map<String, String>> = mutableListOf()
        val bondedDevices: Set<BluetoothDevice> = _adapter!!.bondedDevices
        if (bondedDevices.isNotEmpty()) {
            for (device: BluetoothDevice in bondedDevices) {
                devicesMap.add(device.toMap())
            }
        }
        return devicesMap
    }

    fun send(bytes: ByteArray, onComplete: () -> Unit, onError: (Throwable) -> Unit) {
        _executor.execute {
            try {
                if (!isConnected || _outputStream == null) {
                    onError(Exception("No device connected!"))
                    return@execute
                }
                _outputStream?.write(bytes)
                _outputStream?.flush()
                onComplete()
            } catch (t: Throwable) {
                onError(t)
            }
        }
    }

    @Synchronized
    fun connect(
        deviceAddress: String,
        onResult: (BluetoothDevice) -> Unit,
        onError: (Throwable) -> Unit
    ) {
        if (!_disconnectIfNewAddress(deviceAddress)) {
            onResult(_connectedDevice!!)
            return
        }

        val bondedDevices: Set<BluetoothDevice> = _adapter!!.bondedDevices
        if (bondedDevices.isNotEmpty()) {
            for (device: BluetoothDevice in bondedDevices) {
                if (device.address.equals(deviceAddress)) {
                    _connectedDevice = device
                    break
                }
            }
        }

        if (_connectedDevice == null) {
            onError(Exception("Device not found"))
            return
        }

        _executor.execute {
            try {
                _connect()
                onResult(_connectedDevice!!)
            } catch (t: Throwable) {
                disconnect()
                onError(t)
            }
        }
    }

    fun _closeSocket() {
        _outputStream?.close()
        _outputStream = null
        _socket?.close()
        _socket = null
    }

    fun _connect() {
        _socket = _connectedDevice?.createRfcommSocketToServiceRecord(_uuid)
        _socket?.connect()
        _outputStream = _socket?.outputStream
    }

    /**
     *
     * @return **true** when disconnects, **false** when already connected to device with
     * the same address
     */
    private fun _disconnectIfNewAddress(deviceAddress: String): Boolean {
        if (_connectedDevice?.address == deviceAddress && isConnected) return false
        disconnect()
        return true
    }

    fun disconnect() {
        _closeSocket()
        _connectedDevice = null
    }

    fun dispose() {
        disconnect()
        _executor.shutdown()
    }
}