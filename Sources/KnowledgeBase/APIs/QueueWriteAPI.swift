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
    ///   - content: the queue item
    ///   - identifier: the queue item unique identifier
    ///   - completionHandler: the callback method, called when the operation completes
    public func enqueue(_ content: Any, withIdentifier identifier: String, completionHandler: @escaping KBActionCompletion) {
        self.set(value: content, for: identifier, completionHandler: completionHandler)
    }
    @objc public func enqueue(_ content: Any, for key: String, completionHandler: @escaping KBObjCActionCompletion) {
        KBObjectiveCAPIResultReturningVoid(completionHandler: completionHandler) { c in
            self.enqueue(content, withIdentifier: key, completionHandler: c)
        }
    }
    
    /// Enqueue an item. Blocking version
    /// - Parameters:
    ///   - content: the queue item
    ///   - identifier: the queue item unique identifier
    public func enqueue(_ content: Any, withIdentifier identifier: String) throws {
        try self.set(value: content, for: identifier)
    }
    
    
    /// Enqueue multiple items
    /// - Parameters:
    ///   - contentsByIdentifier: the queue items keyed by identifier
    ///   - completionHandler: the callback method, called when the operation completes
    public func enqueue(_ contentsByIdentifier: KBKVPairs, completionHandler: @escaping KBActionCompletion) {
        let writeBatch = self.writeBatch()
        writeBatch.set(keysAndValues: contentsByIdentifier)
        writeBatch.write(completionHandler: completionHandler)
    }
    @objc public func enqueue(_ contentsByIdentifier: KBKVPairs, completionHandler: @escaping KBObjCActionCompletion) {
        KBObjectiveCAPIResultReturningVoid(completionHandler: completionHandler) { c in
            self.enqueue(contentsByIdentifier, completionHandler: c)
        }
    }
    
    /// Enqueue multiple items. Blocking version
    /// - Parameters:
    ///   - contentsByIdentifier: the queue item
    public func enqueue(_ contentsByIdentifier: KBKVPairs) throws {
        let writeBatch = self.writeBatch()
        writeBatch.set(keysAndValues: contentsByIdentifier)
        try writeBatch.write()
    }
    
    /// Insert an item in the queue with a specific timestamp
    /// - Parameters:
    ///   - content: the queue item
    ///   - identifier: the queue item unique identifier
    ///   - completionHandler: the callback method, called when the operation completes
    public func insert(_ content: Any,
                       withIdentifier identifier: String,
                       timestamp: Date,
                       completionHandler: @escaping KBActionCompletion) {
        self.set(value: content, for: identifier, timestamp: timestamp, completionHandler: completionHandler)
    }
    @objc public func insert(_ content: Any,
                             for key: String,
                             timestamp: Date,
                             completionHandler: @escaping KBObjCActionCompletion) {
        KBObjectiveCAPIResultReturningVoid(completionHandler: completionHandler) { c in
            self.insert(content, withIdentifier: key, timestamp: timestamp, completionHandler: c)
        }
    }
    
    /// Enqueue an item. Blocking version
    /// - Parameters:
    ///   - content: the queue item
    ///   - identifier: the queue item unique identifier
    public func insert(_ content: Any,
                       withIdentifier identifier: String,
                       timestamp: Date) throws {
        try self.set(value: content, for: identifier, timestamp: timestamp)
    }
    
    
    /// Dequeue the next item, based on the queue type
    /// - Parameter completionHandler: the callback method
    public func dequeue(completionHandler: @escaping (Swift.Result<KBQueueItem?, Error>) -> ()) {
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
    @objc public func dequeue(completionHandler: @escaping (Error?, KBQueueItem?) -> ()) {
        KBObjectiveCAPIResultReturningInitiable(completionHandler: completionHandler) { c in
            self.dequeue(completionHandler: c)
        }
    }
    
    /// Dequeue the next item, based on the queue type. Blocking version
    /// - Returns: the dequeued item
    public func dequeue() throws -> KBQueueItem? {
        if let item = try self.peek() {
            try self.removeValue(for: item.identifier)
            return item
        }
        return nil
    }
    
    
    /// Dequeue a specific item (random access)
    /// - Parameter item: the item to dequeue
    /// - Parameter completionHandler: the callback method
    public func dequeue(item: KBQueueItem,
                        completionHandler: @escaping (Swift.Result<KBQueueItem?, Error>) -> ()) {
        self.value(for: item.identifier) { result in
            switch result {
            case .success(let value):
                if let _ = value {
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
    @objc public func dequeue(item: KBQueueItem,
                              completionHandler: @escaping (Error?, KBQueueItem?) -> ()) {
        KBObjectiveCAPIResultReturningInitiable(completionHandler: completionHandler) { c in
            self.dequeue(item: item, completionHandler: c)
        }
    }
    
    /// Dequeue the next item, based on the queue type. Blocking version
    /// - Returns: the dequeued item
    public func dequeue(item: KBQueueItem) throws -> KBQueueItem? {
        if let _ = try self.value(for: item.identifier) {
            try self.removeValue(for: item.identifier)
            return item
        }
        return nil
    }
}
