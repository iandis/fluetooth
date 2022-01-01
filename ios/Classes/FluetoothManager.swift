//
//  FluetoothManager.swift
//  fluetooth
//
//  Created by Iandi Santulus on 27/12/21.
//

import Flutter
import Foundation
import CoreBluetooth

class FluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private let _executor: DeferredExecutor = DeferredExecutor()
//    // Standard SerialPortService ID
//    private static let _serialPortServiceUuid: UUID! = UUID(
//        uuidString: "00001101-0000-1000-8000-00805F9B34FB"
//    )!
    // Generic Access Service ID
//    private static let _genericAccessServiceUuid: UUID! = UUID(
//        uuidString: "00001800-0000-1000-8000-00805F9B34FB"
//    )
    
//    private static let _writeBytesCharacteristicUuid = CBUUID(string: "FFB2")
    
    private var _resultCallback: FlutterResult?

    private var _btManager: CBCentralManager?

    var isAvailable: Bool {
        get {
            return _btManager?.state == .poweredOn
        }
    }
    
    var isConnected: Bool {
        get {
            return _connectedDevice != nil
        }
    }
    
    private var _availableDevices: [CBPeripheral] = []
    private var _availableDevicesMap: [[String:String]] {
        get {
            return _availableDevices.map({
                (device: CBPeripheral) -> [String:String] in
                return device.toMap()
            })
        }
    }

    private var _connectedDevice: CBPeripheral?
    var connectedDevice: [String:String]? {
        get {
            return _connectedDevice?.toMap()
        }
    }
    
    private var _connectedDeviceService: CBService?
    private var _connectedDeviceCharacteristic: CBCharacteristic?

    func initialize() {
        _btManager = CBCentralManager(
            delegate: self,
            queue: .global(qos: .background)
        )
    }
    
    func getAvailableDevices(_ resultCallback: @escaping FlutterResult) {
        _executor.add { [weak self] in
//            do {
            self?._availableDevices.removeAll()
            NSLog("Scanning for BT devices")
//            let connecteds: [CBPeripheral]? = self?._btManager?.retrieveConnectedPeripherals(
//                withServices: [
//                    CBUUID(nsuuid: FluetoothManager._genericAccessServiceUuid)
//                ]
//            )
//
//            let connectedsMap: [[String:String]]? = connecteds?.map({
//                (p: CBPeripheral) -> [String:String] in
//                return p.toMap()
//            })
//
//            NSLog("Connected peripherals: \n\(connectedsMap ?? [])")
            self?._btManager?.scanForPeripherals(
                withServices: nil,
                options: [
                    CBCentralManagerScanOptionAllowDuplicatesKey: false
                ]
            )
            self?._executor.delayed(deadline: .now() + 1) {
                self?._btManager?.stopScan()
                resultCallback(self?._availableDevicesMap ?? [])
            }
//                let cbUuid: CBUUID = CBUUID(nsuuid: FluetoothManager._uuid)
//                guard let peripherals: [CBPeripheral] = self?._btManager?.retrieveConnectedPeripherals(
//                    withServices: FluetoothManager._serviceUUIDs
//                ) else {
//                    throw FluetoothError(message: "Failed to get paired devices!")
//                }
//
//                let devices: [[String:String]] = peripherals.map {
//                    (peripheral: CBPeripheral) -> [String:String] in
//                    return peripheral.toMap()
//                }
            
//            } catch let e {
//                resultCallback(e)
//            }
        }
    }
    
    func connect(uuidString: String, resultCallback: @escaping FlutterResult) {
        _executor.add { [weak self] in
            do {
            let uuid: UUID = UUID(uuidString: uuidString)!
            guard let peripheral: CBPeripheral = self?._availableDevices.first(where: {
                (peripheral: CBPeripheral) -> Bool in
                return peripheral.identifier == uuid
            }) else {
                throw FluetoothError(message: "Device not found!")
            }
            
            //                guard let peripherals: [CBPeripheral] = self?._btManager?.retrievePeripherals(
            //                    withIdentifiers: [uuid]
            //                ) else {
            //                    throw FluetoothError(message: "Failed to retrieve peripherals!")
            //                }
            //
            //                guard let peripheral: CBPeripheral = peripherals.first else {
            //                    throw FluetoothError(message: "Failed to get device!")
            //                }
            self?._resultCallback = resultCallback
            self?._btManager?.connect(peripheral)
            } catch let e as FluetoothError {
                resultCallback(e.toFlutterError())
            } catch let e {
                resultCallback(FlutterError(
                    code: "FLUETOOTH_ERROR",
                    message: e.localizedDescription,
                    details: "connect"
                ))
            }
        }
        
    }
    
    func sendBytes(_ bytes: Data, resultCallback: @escaping FlutterResult) {
        _executor.add(onCompleteNext: true) { [weak self] in
            do {
            guard let connectedDevice: CBPeripheral = self?._connectedDevice else {
                throw FluetoothError(message: "No device connected!")
            }
            
            
//            guard let service: CBService = self?._connectedDeviceServices?.first(
//                where: { (service: CBService) -> Bool in
//                    return service.isPrimary
//                }
//            ) else {
//                resultCallback(FluetoothError(message: "Failed to get services!"))
//                return
//            }
            if self?._connectedDeviceService == nil {
                throw FluetoothError(message: "Failed to send bytes!")
            }
            
            // connectedDevice.discoverCharacteristics(nil, for: service)
            NSLog(String(describing: self?._connectedDeviceService))
            NSLog(String(describing: self?._connectedDeviceCharacteristic))
//            guard let characteristic: CBCharacteristic = self?._connectedDeviceCharacteristics
//            ) else {
//                resultCallback(FluetoothError(message: "Failed to get characteristics!"))
//                return
//            }
            guard let characteristic: CBCharacteristic = self?._connectedDeviceCharacteristic else {
                throw FluetoothError(message: "The printer does not support receiving bytes!")
            }
            
            connectedDevice.writeValue(
                bytes,
                for: characteristic,
                type: .withoutResponse
            )
            
            resultCallback(true)
            } catch let e as FluetoothError {
                resultCallback(e.toFlutterError())
            } catch let e {
                resultCallback(FlutterError(
                    code: "FLUETOOTH_ERROR",
                    message: e.localizedDescription,
                    details: nil
                ))
            }
            
        }
    }
    
    func disconnect(_ resultCallback: @escaping FlutterResult) {
        guard let connectedDevice: CBPeripheral = _connectedDevice else {
            return
        }
        _executor.add { [weak self] in
            self?._resultCallback = resultCallback
            self?._btManager?.cancelPeripheralConnection(connectedDevice)
        }
        
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            NSLog("BT LE powered on!")
        case .poweredOff:
            NSLog("BT LE powered off!")
        case .unauthorized:
            NSLog("BT LE unauthorized!")
        case .unknown:
            NSLog("BT LE unknown!")
        default:
            NSLog("BT LE unsupported!")
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        _connectedDevice = peripheral
        _connectedDevice!.delegate = self
        _connectedDeviceService = nil
        _connectedDeviceCharacteristic = nil
        _connectedDevice!.discoverServices(nil)
        
        _resultCallback?(connectedDevice!)
        _resultCallback = nil
        _executor.next()
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        _connectedDevice = nil
        _connectedDeviceService = nil
        _connectedDeviceCharacteristic = nil
        _resultCallback?(error ?? true)
        _resultCallback = nil
        _executor.next()
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        _connectedDevice = nil
        _connectedDeviceService = nil
        _connectedDeviceCharacteristic = nil
        _resultCallback?(error)
        _resultCallback = nil
        _executor.next()
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        NSLog("Got device: \(peripheral.name ?? "Unknown")")
        let alreadyExists: Bool = _availableDevices.contains(
            where: { $0.identifier == peripheral.identifier }
        )
        if !alreadyExists {
            _availableDevices.append(peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services: [CBService] = peripheral.services, error == nil else {
            _connectedDeviceService = nil
            return
        }
        
        guard let service: CBService = services.first(where: { $0.isPrimary }) else {
            _connectedDeviceService = nil
            return
        }
        
        _connectedDeviceService = service
        peripheral.discoverCharacteristics(nil, for: service)
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        for characteristic in service.characteristics! {
            NSLog("Characteristic found: \(String(describing: characteristic))")
//            NSLog("Decoded value: \(decodedValue ?? "Unknown")")
//            peripheral.readValue(for: characteristic)
            if characteristic.properties.contains(.writeWithoutResponse) {
                NSLog("Characterisitc for writing w/o resp found!: \(characteristic.uuid)")
                _connectedDeviceCharacteristic = characteristic
                break
            }
        }
        
    }
    
//    func peripheral(
//        _ peripheral: CBPeripheral,
//        didUpdateValueFor characteristic: CBCharacteristic,
//        error: Error?
//    ) {
//        guard let value: Data = characteristic.value else { return }
//        let decodedValue: String? = String(bytes: value, encoding: String.Encoding.utf8)
//        NSLog("Decoded value: \(decodedValue ?? "Unknown")")
//    }
    
}
