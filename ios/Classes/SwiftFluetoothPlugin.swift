import Flutter
import CoreBluetooth

public class SwiftFluetoothPlugin: NSObject, FlutterPlugin {
    private static let _channelName: String! = "fluetooth/main"
    
    private let _fluetoothManager: FluetoothManager
    
    init(_ fluetoothMgr: FluetoothManager) {
        _fluetoothManager = fluetoothMgr
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel: FlutterMethodChannel = FlutterMethodChannel(
            name: _channelName,
            binaryMessenger: registrar.messenger()
        )
        
        let fluetoothMgr: FluetoothManager = FluetoothManager()
        fluetoothMgr.initialize()
        let instance: SwiftFluetoothPlugin = SwiftFluetoothPlugin(fluetoothMgr)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            switch call.method {
            case "isAvailable":
                let isAvailable: Bool? = _fluetoothManager.isAvailable
                result(isAvailable)
            case "isConnected":
                let isConnected: Bool = _fluetoothManager.isConnected
                result(isConnected)
            case "connectedDevice":
                let connectedDevice: [String:String]? = _fluetoothManager.connectedDevice
                result(connectedDevice)
            case "getAvailableDevices":
                _fluetoothManager.getAvailableDevices(result)
            case "connect":
                guard let uuidString: String = call.arguments as? String else {
                    throw FluetoothError(message: "Invalid argument for method [connect]")
                }
                _fluetoothManager.connect(
                    uuidString: uuidString,
                    resultCallback: result
                )
            case "disconnect":
                _fluetoothManager.disconnect(result)
            case "sendBytes":
                guard let data: [String:Any] = call.arguments as? [String:Any] else {
                    throw FluetoothError(message: "Invalid argument for method [sendBytes]")
                }
                
                guard let bytes: FlutterStandardTypedData = data["bytes"] as? FlutterStandardTypedData else {
                    throw FluetoothError(message: "Invalid payload for ['bytes']")
                }
                               
                _fluetoothManager.sendBytes(bytes.data, resultCallback: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        } catch let e as FluetoothError {
            result(e.toFlutterError())
        } catch let e {
            result(FlutterError(
                code: "FLUETOOTH_ERROR",
                message: "Uncaught error.",
                details: e.localizedDescription
            ))
        }
    }
}
