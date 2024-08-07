import Foundation

@testable import KnowledgeBase
import XCTest

class KBQueueTestCase: KVStoreTestCase {
    
    private let internalStore = KBQueueStore.store(.inMemory, type: .fifo)!
    
    override func sharedStore() -> KBKVStore {
        internalStore
    }
    
    func sharedQueue() -> KBQueueStore {
        self.sharedStore() as! KBQueueStore
    }
    
    override func setUp() async throws {
        try await self.cleanup()
        try await super.setUp()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        try await self.cleanup()
    }
    
    func testFifoQueue() async throws {
        let items = ["Hello", "world"]
        let itemIds = ["first", "second"]
        try await self.sharedQueue().enqueue(items[0], withIdentifier: itemIds[0])
        try await self.sharedQueue().enqueue(items[1], withIdentifier: itemIds[1])
        var allItems = try await self.sharedQueue().peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 2)
        
        var count = 0
        while let item = try await self.sharedQueue().dequeue() {
            XCTAssertEqual(item.identifier, itemIds[count])
            XCTAssertEqual(item.content as! String, items[count])
            count += 1
        }
        
        allItems = try await self.sharedQueue().peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 0)
    }
    
    func testLifoQueue() async throws {
        let store = KBQueueStore(.inMemory, type: .lifo)!
        
        let items = ["Hello", "world"]
        let itemIds = ["first", "second"]
        try await store.enqueue(items[0], withIdentifier: itemIds[0])
        try await store.enqueue(items[1], withIdentifier: itemIds[1])
        var allItems = try await store.peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 2)
        
        var count = 1
        while let item = try await store.dequeue() {
            XCTAssertEqual(item.identifier, itemIds[count])
            XCTAssertEqual(item.content as! String, items[count])
            count -= 1
        }
        
        allItems = try await store.peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 0)
    }
    
    func testQueueInsert() async throws {
        let store = KBQueueStore(.inMemory, type: .fifo)!
        
        let previousDate = Date().addingTimeInterval(-5 * 60)
        
        let items = ["world", "!"]
        let itemIds = ["second", "fourth"]
        try await store.enqueue(items[0], withIdentifier: itemIds[0])
        let midDate = Date()
        try await store.enqueue(items[1], withIdentifier: itemIds[1])
        var allItems = try await store.peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 2)
        
        try await store.insert("Hello", withIdentifier: "first", timestamp: previousDate)
        try await store.insert(2, withIdentifier: "third", timestamp: midDate)
        try await store.insert(0.1233, withIdentifier: "fifth", timestamp: Date()) // New date is later than date in items[0] and items[1] enqueue
        
        allItems = try await store.peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 5)
        
        guard let firstItem = try await store.dequeue() else {
            XCTFail("'Hello' was not inserted at queue head")
            return
        }
        XCTAssertEqual(firstItem.identifier, "first")
        XCTAssertEqual(firstItem.content as! String, "Hello")
        
        if let item = try await store.dequeue() {
            XCTAssertEqual(item.identifier, itemIds[0])
            XCTAssertEqual(item.content as! String, items[0])
        }
        
        guard let midItem = try await store.dequeue() else {
            XCTFail("'Now.' was not inserted at queue mid")
            return
        }
        XCTAssertEqual(midItem.identifier, "third")
        XCTAssertEqual(midItem.content as! Int, 2)
        
        if let item = try await store.dequeue() {
            XCTAssertEqual(item.identifier, itemIds[1])
            XCTAssertEqual(item.content as! String, items[1])
        }
        
        guard let lastItem = try await store.dequeue() else {
            XCTFail("'Stop.' was not inserted at queue tail")
            return
        }
        XCTAssertEqual(lastItem.identifier, "fifth")
        XCTAssertEqual(lastItem.content as! Double, 0.1233)
        
        allItems = try await self.sharedQueue().peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 0)
    }
    
    func testQueueReplacement() async throws {
        let store = KBQueueStore(.inMemory, type: .fifo)!
        
        let previousDate = Date().addingTimeInterval(-5 * 60)
        
        try await store.enqueue("Hello", withIdentifier: "first")
        try await store.enqueue("world", withIdentifier: "second")
        var allItems = try await store.peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 2)
        
        try await store.enqueue("myself", withIdentifier: "second")
        allItems = try await store.peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 2)
        
        guard let firstItem = try await store.dequeue() else {
            XCTFail("'Hello' was not inserted at queue 0")
            return
        }
        XCTAssertEqual(firstItem.identifier, "first")
        XCTAssertEqual(firstItem.content as! String, "Hello")
        
        guard let secondItem = try await store.dequeue() else {
            XCTFail("'world' was not inserted at queue 1")
            return
        }
        XCTAssertEqual(secondItem.identifier, "second")
        XCTAssertEqual(secondItem.content as! String, "myself")
        
        try await store.enqueue("Hello", withIdentifier: "first")
        try await store.enqueue("world", withIdentifier: "second")
        try await store.insert("other world", withIdentifier: "second", timestamp: previousDate)
        allItems = try await store.peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 2)
        
        guard let firstItem = try await store.dequeue() else {
            XCTFail("'other world' was not inserted at queue 0")
            return
        }
        XCTAssertEqual(firstItem.identifier, "second")
        XCTAssertEqual(firstItem.content as! String, "other world")
        
        guard let secondItem = try await store.dequeue() else {
            XCTFail("'Hello' was not shifted queue 1")
            return
        }
        XCTAssertEqual(secondItem.identifier, "first")
        XCTAssertEqual(secondItem.content as! String, "Hello")
    }
}
