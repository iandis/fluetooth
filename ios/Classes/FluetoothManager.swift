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

    private var _centralManager: CBCentralManager?

    var isAvailable: Bool {
        get {
            return _centralManager?.state == .poweredOn
        }
    }
    
    var isConnected: Bool {
        get {
            return _connectedDevice != nil
        }
    }
    
    private var _availableDeviceUUIDStrings: Set<String> = []
    private var _availableDevices: [CBPeripheral] = []
    private var _availableDevicesMap: [[String:String]] {
        get {
            return _availableDevices.map { $0.toMap() }
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
    private var _dataQueue: DataQueue?

    private var _resultCallback: FlutterResult?

    override init() {
        super.init()
        _centralManager = CBCentralManager(
            delegate: self,
            queue: .global(qos: .background)
        )
    }
    
    func getAvailableDevices(_ resultCallback: @escaping FlutterResult) {
        _executor.add { [weak self] in
            guard let self: FluetoothManager = self else {
                return
            }
            if self._connectedDevice == nil {
                self._availableDeviceUUIDStrings = []
                self._availableDevices = []
            } else {
                self._availableDeviceUUIDStrings = [self._connectedDevice!.identifier.uuidString]
                self._availableDevices = [self._connectedDevice!]
            }
            self._centralManager?.scanForPeripherals(
                withServices: nil,
                options: [
                    CBCentralManagerScanOptionAllowDuplicatesKey: false
                ]
            )
            self._executor.delayed(deadline: .now() + 1) { [weak self] in
                guard let self: FluetoothManager = self else {
                    return
                }
                self._centralManager?.stopScan()
                resultCallback(self._availableDevicesMap)
            }
        }
    }
    
    func connect(uuidString: String, resultCallback: @escaping FlutterResult) {
        _executor.add { [weak self] in
            guard let self: FluetoothManager = self else {
                return
            }
            
            let uuid: UUID = UUID(uuidString: uuidString)!
            
            guard let peripheral: CBPeripheral = self._availableDevices.first(
                where: { $0.identifier == uuid }
            ) else {
                resultCallback(FluetoothError(message: "Device not found").toFlutterError())
                return
            }
            
            self._resultCallback = resultCallback
            self._centralManager?.connect(peripheral)
        }
        
    }
    
    func sendBytes(_ bytes: Data, resultCallback: @escaping FlutterResult) {
        _executor.add { [weak self] in
            guard let self: FluetoothManager = self else {
                return
            }
            guard let connectedDevice: CBPeripheral = self._connectedDevice else {
                resultCallback(FluetoothError(message: "No device connected").toFlutterError())
                self._executor.next()
                return
            }
            guard let characteristic: CBCharacteristic = self._connectedDeviceCharacteristic else {
                resultCallback(FluetoothError(message: "Failed to discover device characteristics").toFlutterError())
                self._executor.next()
                return
            }
            
            let isDeviceSupportWriteWithResponse: Bool = characteristic.properties.contains(.write)
            if isDeviceSupportWriteWithResponse {
                let maxBytesPerWrite: Int = connectedDevice.maximumWriteValueLength(
                    for: .withResponse
                )
                let dataQueue: DataQueue = DataQueue(
                    maxChunkSize: maxBytesPerWrite,
                    bytes: bytes
                )
                guard let firstChunk: Data = dataQueue.next() else {
                    resultCallback(true)
                    self._executor.next()
                    return
                }
                self._dataQueue = dataQueue
                self._resultCallback = resultCallback
                connectedDevice.writeValue(
                    firstChunk,
                    for: characteristic,
                    type: .withResponse
                )
                return
            }
            
            let canSendWriteWithoutResponse: Bool
            if #available(iOS 11.0, *) {
                canSendWriteWithoutResponse = connectedDevice.canSendWriteWithoutResponse
            } else {
                canSendWriteWithoutResponse = true
            }
            let canDeviceWriteWithoutResponse: Bool = characteristic.properties.contains(.writeWithoutResponse) && canSendWriteWithoutResponse
            if canDeviceWriteWithoutResponse {
                connectedDevice.writeValue(
                    bytes,
                    for: characteristic,
                    type: .withoutResponse
                )
                resultCallback(true)
                self._executor.next()
                return
            }
            
            resultCallback(FluetoothError(message: "The device does not support receiving bytes").toFlutterError())
            self._executor.next()
        }
    }

    func disconnect(_ resultCallback: @escaping FlutterResult) {
        _executor.add { [weak self] in
            guard let self: FluetoothManager = self,
                  let connectedDevice: CBPeripheral = self._connectedDevice
            else {
                return
            }
            self._resultCallback = resultCallback
            self._centralManager?.cancelPeripheralConnection(connectedDevice)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .resetting, .poweredOff:
            _connectedDevice = nil
            _connectedDeviceService = nil
            _connectedDeviceCharacteristic = nil
            _availableDevices = []
            _availableDeviceUUIDStrings = []
            _executor.clear()
            _resultCallback?(FluetoothError(message: "Bluetooth powered off").toFlutterError())
            _resultCallback = nil
        default:
            // no-op
            return
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
        let peripheralUuidString: String = peripheral.identifier.uuidString
        guard !_availableDeviceUUIDStrings.contains(peripheralUuidString) else {
            return
        }
        _availableDeviceUUIDStrings.insert(peripheralUuidString)
        _availableDevices.append(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services: [CBService] = peripheral.services,
              error == nil,
              let service: CBService = services.first(where: { $0.isPrimary })
        else {
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
        guard error == nil,
              let characteristics: [CBCharacteristic] = service.characteristics
        else {
            _connectedDeviceCharacteristic = nil
            return
        }
        
        for characteristic in characteristics {
            let props: CBCharacteristicProperties = characteristic.properties
            if props.contains(.write) || props.contains(.writeWithoutResponse) {
                _connectedDeviceCharacteristic = characteristic
                break
            }
        }
        
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard let dataQueue: DataQueue = _dataQueue else {
            return
        }
        
        if let e: Error = error {
            _dataQueue = nil
            _resultCallback?(FluetoothError(message: e.localizedDescription).toFlutterError())
            _resultCallback = nil
            _executor.next()
            return
        }
        
        if dataQueue.isComplete {
            _dataQueue = nil
            _resultCallback?(true)
            _resultCallback = nil
            _executor.next()
            return
        }
        
        _executor.now {
            guard let nextChunk: Data = dataQueue.next() else {
                return
            }
            peripheral.writeValue(
                nextChunk,
                for: characteristic,
                type: .withResponse
            )
        }
    }
}
