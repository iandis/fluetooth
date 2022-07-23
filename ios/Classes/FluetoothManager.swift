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

    override init() {
        super.init()
        _btManager = CBCentralManager(
            delegate: self,
            queue: .global(qos: .background)
        )
    }
    
    func getAvailableDevices(_ resultCallback: @escaping FlutterResult) {
        _executor.add { [weak self] in
            self?._availableDevices.removeAll()
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
                
                if self?._connectedDeviceService == nil {
                    throw FluetoothError(message: "Failed to send bytes!")
                }
                
                guard let characteristic: CBCharacteristic = self?._connectedDeviceCharacteristic else {
                    throw FluetoothError(message: "The device does not support receiving bytes!")
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

    func centralManagerDidUpdateState(_ central: CBCentralManager) {}
    
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
        if let characteristics: [CBCharacteristic] = service.characteristics {
            for characteristic in characteristics {
                let props: CBCharacteristicProperties = characteristic.properties
                if props.contains(.writeWithoutResponse) || props.contains(.write) {
                    _connectedDeviceCharacteristic = characteristic
                    break
                }
            }
        } else {
            _connectedDeviceCharacteristic = nil
        }
        
    }

}
