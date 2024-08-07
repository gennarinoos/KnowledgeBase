import Foundation

// MARK: - KBQueueStore Write API

extension KBQueueStore {
    
    /// Enqueue an item
    /// - Parameters:
    ///   - content: the queue item
    ///   - identifier: the queue item unique identifier
    public func enqueue(_ content: Any, withIdentifier identifier: String) async throws {
        try await self.set(value: content, for: identifier)
    }
    
    /// Enqueue multiple items
    /// - Parameters:
    ///   - contentsByIdentifier: the queue items keyed by identifier
    public func enqueue(_ contentsByIdentifier: KBKVPairs) async throws {
        let writeBatch = self.writeBatch()
        writeBatch.set(keysAndValues: contentsByIdentifier)
        try await writeBatch.write()
    }
    
    /// Insert an item in the queue with a specific timestamp
    /// - Parameters:
    ///   - content: the queue item
    ///   - identifier: the queue item unique identifier
    public func insert(_ content: Any,
                       withIdentifier identifier: String,
                       timestamp: Date) async throws {
        try await self.set(
            value: content,
            for: identifier,
            timestamp: timestamp
        )
    }
    
    /// Dequeue the next item, based on the queue type
    public func dequeue() async throws -> KBQueueItem? {
        if let item = try await self.peek() {
            try await self.removeValue(for: item.identifier)
            return item
        }
        return nil
    }
    
    /// Dequeue a specific item (random access)
    /// - Parameter item: the item to dequeue
    public func dequeue(
        item: KBQueueItem
    ) async throws -> KBQueueItem? {
        if let _ = try await self.value(for: item.identifier) {
            try await self.removeValue(for: item.identifier)
            return item
        }
        return nil
    }
}
