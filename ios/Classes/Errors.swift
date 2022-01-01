//
//  Errors.swift
//  fluetooth
//
//  Created by Iandi Santulus on 27/12/21.
//

import Flutter
import Foundation

struct FluetoothError: Error {
    let message: String
    
    func toFlutterError() -> FlutterError {
        return FlutterError(
            code: "FLUETOOTH_ERROR",
            message: message,
            details: nil
        )
    }
}
