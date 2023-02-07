package app.iandis.fluetooth

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FluetoothPlugin : FlutterPlugin, MethodCallHandler {
    private val _channelName: String = "fluetooth/main"

    private lateinit var _channel: MethodChannel
    private var _fluetoothManager: FluetoothManager? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPluginBinding) {
        _channel = MethodChannel(flutterPluginBinding.binaryMessenger, _channelName)
        _channel.setMethodCallHandler(this)
        val context: Context = flutterPluginBinding.applicationContext
        val bluetoothManager: BluetoothManager? =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
        val adapter: BluetoothAdapter? = bluetoothManager?.adapter
        _fluetoothManager = FluetoothManager(adapter)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            when (call.method) {
                "isAvailable" -> {
                    val isAvailable: Boolean? = _fluetoothManager!!.isAvailable
                    result.success(isAvailable)
                }
                "isConnected" -> {
                    val isConnected: Boolean = _fluetoothManager!!.isConnected
                    result.success(isConnected)
                }
                "connectedDevice" -> {
                    val connectedDevice: Map<String, String>? = _fluetoothManager!!.connectedDevice
                    result.success(connectedDevice)
                }
                "getAvailableDevices" -> {
                    val availableDevices: List<Map<String, String>> =
                        _fluetoothManager!!.getAvailableDevices()
                    result.success(availableDevices)
                }
                "connect" -> {
                    if (_fluetoothManager!!.isAvailable != true) {
                        throw Exception("Bluetooth is not available.")
                    }
                    val targetDevice: Any = call.arguments
                    if (targetDevice is String) {
                        _fluetoothManager!!.connect(targetDevice, { device ->
                            val connectedDevice: Map<String, String> = device.toMap()
                            result.success(connectedDevice)
                        }, {
                            result.error(
                                "FLUETOOTH_CONNECT_ERROR",
                                "Failed to connect to $targetDevice",
                                null
                            )
                        })
                    } else {
                        throw IllegalArgumentException("targetDevice should be a string")
                    }
                }
                "disconnect" -> {
                    _fluetoothManager!!.disconnect()
                    result.success(true)
                }
                "sendBytes" -> {
                    if (_fluetoothManager!!.isAvailable != true) {
                        throw Exception("Bluetooth is not available.")
                    }
                    if (!_fluetoothManager!!.isConnected) {
                        throw Exception("Not connected!")
                    }
                    val arguments: Any = call.arguments
                    if (arguments is Map<*, *>) {
                        val bytes: ByteArray = arguments["bytes"] as ByteArray
                        _fluetoothManager!!.send(bytes, {
                            result.success(true)
                        }, {
                            result.error("FLUETOOTH_ERROR", it.message, it.cause)
                        })
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

    override fun onDetachedFromEngine(@NonNull binding: FlutterPluginBinding) {
        _channel.setMethodCallHandler(null)
        _fluetoothManager!!.dispose()
        _fluetoothManager = null
    }
}
