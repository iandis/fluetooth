package app.iandis.fluetooth

import android.content.Context
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FluetoothPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var _fluetoothManager: FluetoothManager? = null
    private var _context: Context? = null

    companion object {
        private const val _channelName: String = "fluetooth/main"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, _channelName)
        channel.setMethodCallHandler(this)
        _context = flutterPluginBinding.applicationContext
        _fluetoothManager = FluetoothManager(_context!!)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            when (call.method) {
                "isConnected" -> {
                    val isConnected: Boolean = _fluetoothManager!!.isConnected
                    result.success(isConnected)
                }
                "isAvailable" -> {
                    val isAvailable: Boolean? = _fluetoothManager!!.isAvailable
                    result.success(isAvailable)
                }
                "connectedDevice" -> {
                    val connectedDevice: Map<String, String>? = _fluetoothManager!!.connectedDevice
                    result.success(connectedDevice)
                }
                "getPairedDevices" -> {
                    val pairedDevices: List<Map<String, String>> =
                        _fluetoothManager!!.getPairedDevices()
                    result.success(pairedDevices)
                }
                "connect" -> {
                    if (_fluetoothManager!!.isAvailable != true) {
                        throw Exception("Bluetooth is not available.")
                    }
                    if (_fluetoothManager!!.isConnected) {
                        throw Exception("Already connected!")
                    }
                    val targetDevice: Any = call.arguments
                    if (targetDevice is String) {
                        _fluetoothManager!!.connect(targetDevice)
                    } else {
                        throw IllegalArgumentException("targetDevice should be a string")
                    }
                }
                "disconnect" -> {
                    _fluetoothManager!!.disconnect()
                }
                "writeBytes" -> {
                    if (_fluetoothManager!!.isAvailable != true) {
                        throw Exception("Bluetooth is not available.")
                    }
                    if (!_fluetoothManager!!.isConnected) {
                        throw Exception("Not connected!")
                    }
                    val arguments: Any = call.arguments
                    if (arguments is Map<*, *>) {
                        val bytes: ByteArray = arguments["bytes"] as ByteArray
                        val chunkSize: Int? = arguments["chunkSize"] as? Int
                        _writeBytes(bytes, chunkSize)
                    } else {
                        throw IllegalArgumentException("arguments should be a Map")
                    }
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error(
                "FLUETOOTH_ERROR",
                e.message,
                e.cause
            )
        }
    }

    private fun _writeBytes(bytes: ByteArray, chunkSize: Int? = null) {
        if (chunkSize != null && chunkSize > 0 && chunkSize < bytes.size) {
            val chunks: Int = bytes.size / chunkSize
            val lastChunk: Int = bytes.size % chunkSize
            for (i in 0..chunks) {
                _fluetoothManager!!.writeBytes(
                    bytes.copyOfRange(
                        i * chunkSize,
                        (i + 1) * chunkSize
                    )
                )
                _fluetoothManager!!.flush()
            }
            if (lastChunk > 0) {
                _fluetoothManager!!.writeBytes(
                    bytes.copyOfRange(
                        chunks * chunkSize,
                        bytes.size
                    )
                )
                _fluetoothManager!!.flush()
            }
        } else {
            _fluetoothManager!!.writeBytes(bytes)
            _fluetoothManager!!.flush()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        _fluetoothManager!!.disconnect()
        _context = null
        _fluetoothManager = null
    }
}
