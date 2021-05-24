//
//  LazyAtomic.swift
//
//
//  Created by Guillermo Muntaner Perelló on 16/06/2019.
//

import Foundation

/// A property wrapper which delays instantiation until first read access.
///
/// It is a reimplementation of Swift `lazy` modifier using a property wrapper.
/// As an extra on top of `lazy` it offers reseting the wrapper to its "uninitialized" state.
///
/// Usage:
/// ```
/// @LazyAtomic var result = expensiveOperation()
/// ...
/// print(result) // expensiveOperation() is executed at this point
/// ```
///
/// As an extra on top of `lazy` it offers reseting the wrapper to its "uninitialized" state.
@propertyWrapper
public struct LazyAtomic<Value> {
    let queue = DispatchQueue(label: "Atomic write access queue", attributes: .concurrent)

    var storage: Value?
    let constructor: () -> Value

    /// Creates a lazy property with the closure to be executed to provide an initial value once the wrapped property is first accessed.
    ///
    /// This constructor is automatically used when assigning the initial value of the property, so simply use:
    ///
    ///     @LazyAtomic var text = "Hello, World!"
    ///
    public init(wrappedValue constructor: @autoclosure @escaping () -> Value) {
        self.constructor = constructor
    }

    public var wrappedValue: Value {
        mutating get {
            queue.sync {
                if storage == nil {
                    self.storage = constructor()
                }
                return storage!
            }
        }
        set {
            queue.sync(flags: .barrier) { storage = newValue }
        }
    }

    // MARK: Utils

    /// Atomically mutate the variable (read-modify-write).
    ///
    /// - parameter action: A closure executed with atomic in-out access to the wrapped property.
    public mutating func mutate(_ mutation: (inout Value) throws -> Void) rethrows {
        return try queue.sync(flags: .barrier) {
            if storage == nil {
                self.storage = constructor()
            }
            try mutation(&(storage!))
        }
    }

    /// Resets the wrapper to its initial state. The wrapped property will be initialized on next read access.
    public mutating func reset() {
        storage = nil
    }
}
