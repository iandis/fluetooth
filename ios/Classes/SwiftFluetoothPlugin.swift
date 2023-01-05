import Flutter
import CoreBluetooth

public class SwiftFluetoothPlugin: NSObject, FlutterPlugin {
    private static let _channelName: String! = "fluetooth/main"
    
    private var _fluetoothManager: FluetoothManager?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel: FlutterMethodChannel = FlutterMethodChannel(
            name: _channelName,
            binaryMessenger: registrar.messenger()
        )
        
        let instance: SwiftFluetoothPlugin = SwiftFluetoothPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if _fluetoothManager == nil {
            _fluetoothManager = FluetoothManager()
        }
        switch call.method {
        case "isAvailable":
            let isAvailable: Bool = _fluetoothManager!.isAvailable
            result(isAvailable)
        case "isConnected":
            let isConnected: Bool = _fluetoothManager!.isConnected
            result(isConnected)
        case "connectedDevice":
            let connectedDevice: [String:String]? = _fluetoothManager!.connectedDevice
            result(connectedDevice)
        case "getAvailableDevices":
            _fluetoothManager!.getAvailableDevices(result)
        case "connect":
            guard let uuidString: String = call.arguments as? String else {
                result(FluetoothError(message: "Invalid argument for method [connect]").toFlutterError())
                return
            }
            _fluetoothManager!.connect(
                uuidString: uuidString,
                resultCallback: result
            )
        case "disconnect":
            _fluetoothManager!.disconnect(result)
        case "sendBytes":
            guard let data: [String:Any] = call.arguments as? [String:Any] else {
                result(FluetoothError(message: "Invalid argument for method [sendBytes]").toFlutterError())
                return
            }
            
            guard let bytes: FlutterStandardTypedData = data["bytes"] as? FlutterStandardTypedData else {
                result(FluetoothError(message: "Invalid payload for ['bytes']").toFlutterError())
                return
            }
            _fluetoothManager!.sendBytes(bytes.data, resultCallback: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
