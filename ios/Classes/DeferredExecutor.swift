//
//  SerialExecutor.swift
//  fluetooth
//
//  Created by Iandi Santulus on 27/12/21.
//

import Foundation

class DeferredExecutor {
    
    private let _dispatcher: DispatchQueue = DispatchQueue(
        label: "fluetooth-executor",
        qos: .background
//        attributes: DispatchQueue.Attributes(),
//        autoreleaseFrequency: .inherit,
//        target: DispatchQueue.global(qos: .background)
    )
    private var _tasks: [() -> Void] = []
    private var _activeTask: (() -> Void)?
//    private var _canNext: Bool = false
//    var isActivated: Bool {
//        get {
//            return _canNext
//        }
//    }
//
//    func activate() {
//        _canNext = true
//        next()
//    }

    func add(
        onCompleteNext: Bool = false,
        _ callback: @escaping () throws -> Void
    ) {
        _tasks.append { [weak self] in
            try? callback()
            if onCompleteNext {
                self?.next()
            }
        }
        if _activeTask == nil {
            next()
        }
    }
    
    func delayed(
        onCompleteNext: Bool = true,
        deadline: DispatchTime,
        _ callback: @escaping () throws -> Void
    ) {
        _dispatcher.asyncAfter(deadline: deadline) { [weak self] in
            try? callback()
            if onCompleteNext {
                self?.next()
            }
        }
    }

    func next() {
        _activeTask = _tasks.isEmpty ? nil : _tasks.removeFirst()
        if _activeTask != nil {
            _dispatcher.sync {
                _activeTask!()
            }
        }
    }
}
