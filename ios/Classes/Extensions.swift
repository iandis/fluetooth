//
//  Extensions.swift
//  fluetooth
//
//  Created by Iandi Santulus on 27/12/21.
//

import CoreBluetooth

extension CBPeripheral {
    
    func toMap() -> [String: String] {
        return [
            "name": name ?? "",
            "id": identifier.uuidString
        ]
    }
}

extension Error {
    
    func toFlutterError() -> FlutterError {
        return FluetoothError(message: localizedDescription).toFlutterError()
    }
}
