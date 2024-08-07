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
     
     */
    public func peekItems(
        createdWithin interval: DateInterval,
        limit: Int? = nil,
        overrideSort: KBSortDirection? = nil
    ) async throws -> [KBQueueItem] {
        guard limit == nil || limit! > 0 else {
            throw KBError.notSupported
        }
        
        let order = overrideSort ?? (self.queueType == .fifo ? .ascending : .descending)
        let itemsKeyedByDate = try await self.backingStore.dictionaryRepresentation(
            createdWithin: interval,
            paginate: limit != nil ? KBPaginationOptions(limit: limit!, offset: 0) : nil,
            sort: order
        )
        return try toQueueItems(itemsKeyedByDate: itemsKeyedByDate).sorted { $0.createdAt > $1.createdAt }
    }
    
    /**
     Retrieves the next item in the queue, according to the policy for the queue type (fifo, lifo)

     */
    public func peek() async throws -> KBQueueItem? {
        try await self.peekItems(
            createdWithin: DateInterval(start: Date.distantPast, end: Date()),
            limit: 1
        ).first
    }
    
    /**
     Retrieves the next `count` items in the queue, according to the policy for the queue type (fifo, lifo)
     Blocking version.
     
     - Parameter count: the number of queue items to pull
     - returns: the next item in the queue
     
     */
    public func peekNext(_ count: Int) async throws -> [KBQueueItem] {
        try await self.peekItems(createdWithin: DateInterval(start: Date.distantPast, end: Date()), limit: count)
    }
    
    /**
     Retrieves a specific item in the queue if exists, given an identifier
     
     - parameter identifier: the item identifier in the queue
     
     */
    public func retrieveItem(withIdentifier identifier: String) async throws -> KBQueueItem? {
        try await self.retrieveItems(withIdentifiers: [identifier]).first
    }
    
    /**
     Retrieves a list of items in the queue if they exists, given their identifires
     
     - parameter identifiers: the identifiers of the items in the queue
     
     */
    public func retrieveItems(withIdentifiers identifiers: [String]) async throws -> [KBQueueItem] {
        var condition = KBGenericCondition(value: false)
        for queueItemIdentifier in identifiers {
            condition = condition.or(KBGenericCondition(.equal, value: queueItemIdentifier))
        }
        return try await self.retrieveItems(withIdentifiersMatching: condition)
    }
    
    /**
     Retrieves a list of items in the queue if they exists, given a condition to be appllied to their identifiers
     
     - parameter withIdentifiersMatching: the condition to apply to the item identifiers
     
     */
    public func retrieveItems(
        withIdentifiersMatching condition: KBGenericCondition
    ) async throws -> [KBQueueItem] {
        let kvPairsWithTimestamps = try await self.keyValuesAndTimestamps(
            forKeysMatching: condition,
            timestampMatching: nil,
            sort: (self.queueType == .fifo ? .ascending : .descending)
        )
         
        var items = [KBQueueItem]()
        for kvPairWithTimestamp in kvPairsWithTimestamps {
            guard let value = kvPairWithTimestamp.value else {
                throw KBError.unexpectedData(kvPairsWithTimestamps)
            }
            let item = KBQueueItem(
                identifier: kvPairWithTimestamp.key,
                content: value,
                createdAt: kvPairWithTimestamp.timestamp
            )
            items.append(item)
        }
        
        return items
    }
}

