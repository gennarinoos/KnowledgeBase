//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 9/4/21.
//

import Foundation

// MARK: - KBQueueStore Write API

extension KBQueueStore {
    
    /// Enqueue an item
    /// - Parameters:
    ///   - value: the queue item
    ///   - identifier: the queue item unique identifier
    ///   - completionHandler: the callback method, called when the operation completes
    open func enqueue(_ value: Any, withIdentifier identifier: String, completionHandler: @escaping KBActionCompletion) {
        self.set(value: value, for: identifier, completionHandler: completionHandler)
    }
    @objc open func enqueue(_ value: Any, for key: String, completionHandler: @escaping KBObjCActionCompletion) {
        KBObjectiveCAPIResultReturningVoid(completionHandler: completionHandler) { c in
            self.enqueue(value, withIdentifier: key, completionHandler: c)
        }
    }
    
    
    /// Enqueue an item. Blocking version
    /// - Parameters:
    ///   - value: the queue item
    ///   - identifier: the queue item unique identifier
    open func enqueue(_ value: Any, withIdentifier identifier: String) throws {
        try self.set(value: value, for: identifier)
    }
    
    /// Enqueue multiple items
    /// - Parameters:
    ///   - valuesByIdentifier: the queue items keyed by identifier
    ///   - completionHandler: the callback method, called when the operation completes
    open func enqueue(_ valuesByIdentifier: KBKVPairs, completionHandler: @escaping KBActionCompletion) {
        let writeBatch = self.writeBatch()
        writeBatch.set(keysAndValues: valuesByIdentifier)
        writeBatch.write(completionHandler: completionHandler)
    }
    @objc open func enqueue(_ valuesByIdentifier: KBKVPairs, completionHandler: @escaping KBObjCActionCompletion) {
        KBObjectiveCAPIResultReturningVoid(completionHandler: completionHandler) { c in
            self.enqueue(valuesByIdentifier, completionHandler: c)
        }
    }
    
    
    /// Enqueue multiple items. Blocking version
    /// - Parameters:
    ///   - valuesByIdentifier: the queue item
    open func enqueue(_ valuesByIdentifier: KBKVPairs) throws {
        let writeBatch = self.writeBatch()
        writeBatch.set(keysAndValues: valuesByIdentifier)
        try writeBatch.write()
    }
    
    
    /// Dequeue the next item, based on the queue type
    /// - Parameter completionHandler: the callback method
    open func dequeue(completionHandler: @escaping (Swift.Result<KBQueueItem?, Error>) -> ()) {
        self.peek() { result in
            switch result {
            case .success(let item):
                if let item = item {
                    self.removeValue(for: item.identifier) {
                        (result: Swift.Result) in
                        switch result {
                        case .success():
                            completionHandler(.success(item))
                        case .failure(let error):
                            completionHandler(.failure(error))
                        }
                    }
                }
                completionHandler(.success(nil))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    @objc open func dequeue(completionHandler: @escaping (Error?, KBQueueItem?) -> ()) {
        KBObjectiveCAPIResultReturningInitiable(completionHandler: completionHandler) { c in
            self.dequeue(completionHandler: c)
        }
    }
    
    /// Dequeue the next item, based on the queue type. Blocking version
    /// - Returns: the dequeued item
    open func dequeue() throws -> KBQueueItem? {
        if let item = try self.peek() {
            try self.removeValue(for: item.identifier)
            return item
        }
        return nil
    }
}
