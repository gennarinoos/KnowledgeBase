//
//  QueueReadAPI.swift
//  
//
//  Created by Gennaro Frazzingaro on 9/4/21.
//

import Foundation

// MARK: - KBQueueStore Read API

func toQueueItems(itemsKeyedByDate: [Date: KBKVPairs]) throws -> [KBQueueItem] {
    var queueItems = [KBQueueItem]()
    for (date, item) in itemsKeyedByDate {
        do {
            queueItems.append(try KBQueueItem(item: item, createdAt: date))
        } catch {
            throw KBError.unexpectedData(item)
        }
    }
    return queueItems
}

extension KBQueueStore {
    
    /**
     Retrieves all queue items created within the provided time range, sorted in the order determined by the queue type (fifo, lifo)
     
     - parameter createdWithin: the time range
     - parameter limit: limits the number of items
     - parameter completionHandler: the callback method
     
     */
    public func peekItems(createdWithin interval: DateInterval,
                          limit: Int? = nil,
                          overrideOrder: ComparisonResult? = nil,
                          completionHandler: @escaping (Swift.Result<[KBQueueItem], Error>) -> ()) {
        let order = overrideOrder ?? (self.queueType == .fifo ? ComparisonResult.orderedAscending : ComparisonResult.orderedDescending)
        return self.backingStore.dictionaryRepresentation(createdWithin: interval, limit: limit, order: order) { result in
            switch result {
            case .success(let itemsKeyedByDate):
                do {
                    let items = try toQueueItems(itemsKeyedByDate: itemsKeyedByDate).sorted { $0.createdAt > $1.createdAt }
                    completionHandler(.success(items))
                } catch {
                    completionHandler(.failure(error))
                    return
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    @objc public func peekItems(createdWithin interval: DateInterval,
                                limit: Int = -1,
                                completionHandler: @escaping (Error?, [KBQueueItem]) -> ()) {
        KBObjectiveCAPIResultReturningInitiable(completionHandler: completionHandler) {
            c in
            self.peekItems(createdWithin: interval, limit: limit, completionHandler: c)
        }
    }
    
    
    /**
     Retrieves all keys and values in the KVS, for pairs created within a time range, sorted in the order determined by the queue type (fifo, lifo)
     Blocking version.
     
     - parameter createdWithin: the time range
     - parameter limit: limits the number of items
     - returns: the list of items
     
     */
    public func peekItems(createdWithin interval: DateInterval, limit: Int? = nil) throws -> [KBQueueItem] {
        let order = self.queueType == .fifo ? ComparisonResult.orderedAscending : ComparisonResult.orderedDescending
        let itemsKeyedByDate = try self.backingStore.dictionaryRepresentation(createdWithin: interval, limit: limit, order: order)
        return try toQueueItems(itemsKeyedByDate: itemsKeyedByDate)
    }
    
    /**
     Retrieves the next item in the queue, according to the policy for the queue type (fifo, lifo)
     
     - parameter completionHandler: the callback method

     */
    public func peek(completionHandler: @escaping (Swift.Result<KBQueueItem?, Error>) -> ()) {
        self.peekItems(createdWithin: DateInterval(start: Date.distantPast, end: Date()),
                   limit: 1) { result in
            switch result {
            case .success(let resultByDate):
                completionHandler(.success(resultByDate.first))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    @objc public func peek(completionHandler: @escaping (Error?, KBQueueItem?) -> ()) {
        KBObjectiveCAPIResultReturningInitiable(completionHandler: completionHandler) {
            c in
            self.peek(completionHandler: c)
        }
    }
    
    /**
     Retrieves the next item in the queue, according to the policy for the queue type (fifo, lifo)
     Blocking version.
     
     - returns: the next item in the queue
     
     */
    public func peek() throws -> KBQueueItem? {
        return try self.peekItems(createdWithin: DateInterval(start: Date.distantPast, end: Date()), limit: 1).first
    }
    
    /**
     Retrieves the next `count` items in the queue, according to the policy for the queue type (fifo, lifo)
     
     - parameter completionHandler: the callback method

     */
    public func peekNext(_ count: Int,
                         completionHandler: @escaping (Swift.Result<[KBQueueItem], Error>) -> ()) {
        self.peekItems(createdWithin: DateInterval(start: Date.distantPast, end: Date()),
                       limit: count,
                       completionHandler: completionHandler)
    }
    @objc public func peekNext(_ count: Int,
                               completionHandler: @escaping (Error?, [KBQueueItem]) -> ()) {
        KBObjectiveCAPIResultReturningInitiable(completionHandler: completionHandler) {
            c in
            self.peekNext(count, completionHandler: c)
        }
    }
    
    /**
     Retrieves the next `count` items in the queue, according to the policy for the queue type (fifo, lifo)
     Blocking version.
     
     - Parameter count: the number of queue items to pull
     - returns: the next item in the queue
     
     */
    public func peekNext(_ count: Int) throws -> [KBQueueItem] {
        return try self.peekItems(createdWithin: DateInterval(start: Date.distantPast, end: Date()), limit: count)
    }
    
    /**
     Retrieves a specific item in the queue if exists, given an identifier
     
     - parameter identifier: the item identifier in the queue
     - parameter completionHandler: the callback method
     
     */
    public func retrieveItem(withIdentifier identifier: String, completionHandler: @escaping (Swift.Result<KBQueueItem?, Error>) -> ()) {
        self.retrieveItems(withIdentifiers: [identifier]) { result in
            switch result {
            case .success(let items):
                if items.count == 0 {
                    completionHandler(.success(nil))
                }
                else if items.count > 1 {
                    completionHandler(.failure(KBError.unexpectedData(items)))
                }
                else {
                    completionHandler(.success(items.first))
                }
            case .failure(let err):
                completionHandler(.failure(err))
            }
        }
    }
    @objc public func retrieveItem(withIdentifier identifier: String, completionHandler: @escaping (Error?, KBQueueItem?) -> ()) {
        KBObjectiveCAPIResultReturningInitiable(completionHandler: completionHandler) {
            c in
            self.retrieveItem(withIdentifier: identifier, completionHandler: c)
        }
    }
    
    /**
     Retrieves a list of items in the queue if they exists, given their identifires
     
     - parameter identifiers: the identifiers of the items in the queue
     - parameter completionHandler: the callback method
     
     */
    public func retrieveItems(withIdentifiers identifiers: [String], completionHandler: @escaping (Swift.Result<[KBQueueItem], Error>) -> ()) {
        var condition = KBGenericCondition(value: false)
        for queueItemIdentifier in identifiers {
            condition = condition.or(KBGenericCondition(.equal, value: queueItemIdentifier))
        }
        self.keyValuesAndTimestamps(forKeysMatching: condition) { result in
            switch result {
            case .success(let kvPairsWithTimestamps):
                var items = [KBQueueItem]()
                for kvPairWithTimestamp in kvPairsWithTimestamps {
                    guard let value = kvPairWithTimestamp.value else {
                        completionHandler(.failure(KBError.unexpectedData(kvPairsWithTimestamps)))
                        return
                    }
                    let item = KBQueueItem(
                        identifier: kvPairWithTimestamp.key,
                        content: value,
                        createdAt: kvPairWithTimestamp.timestamp
                    )
                    items.append(item)
                }
                completionHandler(.success(items))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    @objc public func retrieveItems(withIdentifiers identifiers: [String], completionHandler: @escaping (Error?, [KBQueueItem]) -> ()) {
        KBObjectiveCAPIResultReturningInitiable(completionHandler: completionHandler) {
            c in
            self.retrieveItems(withIdentifiers: identifiers, completionHandler: c)
        }
    }
}

