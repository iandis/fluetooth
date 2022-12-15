//
//  DataQueue.swift
//  fluetooth
//
//  Created by Iandi Santulus on 22/11/22.
//

import Foundation
import CoreBluetooth

class DataQueue {
    private static let _MAX_ATT_MTU: Int = 240

    init(maxChunkSize: Int, bytes: Data)  {
        self.maxChunkSize = min(maxChunkSize, DataQueue._MAX_ATT_MTU)
        _bytesToWrite = bytes.count
        _bytes = bytes
    }

    let maxChunkSize: Int
    private let _bytesToWrite: Int
    private var _bytesWritten: Int = 0
    private let _bytes: Data

    var isComplete: Bool {
        get {
            return _bytesWritten == _bytesToWrite
        }
    }

    func next() -> Data? {
        if isComplete {
            return nil
        }
        let chunkSize: Int = min(maxChunkSize, _bytesToWrite - _bytesWritten)
        let byteEndIndex: Int = _bytesWritten + chunkSize
        let chunk: Data = _bytes.subdata(in: _bytesWritten..<byteEndIndex)
        _bytesWritten += chunkSize
        return chunk
    }
}
