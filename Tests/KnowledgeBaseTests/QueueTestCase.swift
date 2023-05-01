//
//  QueueTestCase.swift
//  
//
//  Created by Gennaro Frazzingaro on 9/4/21.
//

import Foundation

@testable import KnowledgeBase
import XCTest

class KBQueueTestCase: KVStoreTestCase {
    
    private static let _sharedStore = KBQueueStore.store(.inMemory, type: .fifo)
    
    override func sharedStore() -> KBQueueStore {
        return KBQueueTestCase._sharedStore
    }
    
    private func cleanup() {
        do {
            let store = self.sharedStore()
            let _ = try store.removeAll()
            let keys = try store.keys()
            XCTAssert(keys.count == 0, "Removed all values")
        } catch {
            XCTFail("\(error)")
        }
    }
    
    override func setUp() {
        self.cleanup()
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        self.cleanup()
    }
    
    func testFifoQueue() throws {
        let items = ["Hello", "world"]
        let itemIds = ["first", "second"]
        try self.sharedStore().enqueue(items[0], withIdentifier: itemIds[0])
        try self.sharedStore().enqueue(items[1], withIdentifier: itemIds[1])
        var allItems = try self.sharedStore().peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 2)
        
        var count = 0
        while let item = try self.sharedStore().dequeue() {
            XCTAssertEqual(item.identifier, itemIds[count])
            XCTAssertEqual(item.content as! String, items[count])
            count += 1
        }
        
        allItems = try self.sharedStore().peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 0)
    }
    
    func testLifoQueue() throws {
        let store = KBQueueStore(.inMemory, type: .lifo)
        
        let items = ["Hello", "world"]
        let itemIds = ["first", "second"]
        try store.enqueue(items[0], withIdentifier: itemIds[0])
        try store.enqueue(items[1], withIdentifier: itemIds[1])
        var allItems = try store.peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 2)
        
        var count = 1
        while let item = try store.dequeue() {
            XCTAssertEqual(item.identifier, itemIds[count])
            XCTAssertEqual(item.content as! String, items[count])
            count -= 1
        }
        
        allItems = try store.peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 0)
    }
    
    func testQueueInsert() throws {
        let store = KBQueueStore(.inMemory, type: .fifo)
        
        let previousDate = Date().addingTimeInterval(-5 * 60)
        
        let items = ["world", "!"]
        let itemIds = ["second", "fourth"]
        try store.enqueue(items[0], withIdentifier: itemIds[0])
        let midDate = Date()
        try store.enqueue(items[1], withIdentifier: itemIds[1])
        var allItems = try store.peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 2)
        
        try store.insert("Hello", withIdentifier: "first", timestamp: previousDate)
        try store.insert("Now.", withIdentifier: "third", timestamp: midDate)
        try store.insert("Stop.", withIdentifier: "fifth", timestamp: Date()) // New date is later than date in items[0] and items[1] enqueue
        
        guard let firstItem = try store.dequeue() else {
            XCTFail("'Hello' was not inserted at queue head")
            return
        }
        XCTAssertEqual(firstItem.identifier, "first")
        XCTAssertEqual(firstItem.content as! String, "Hello")
        
        if let item = try store.dequeue() {
            XCTAssertEqual(item.identifier, itemIds[0])
            XCTAssertEqual(item.content as! String, items[0])
        }
        
        guard let midItem = try store.dequeue() else {
            XCTFail("'Now.' was not inserted at queue mid")
            return
        }
        XCTAssertEqual(midItem.identifier, "third")
        XCTAssertEqual(midItem.content as! String, "Now.")
        
        if let item = try store.dequeue() {
            XCTAssertEqual(item.identifier, itemIds[1])
            XCTAssertEqual(item.content as! String, items[1])
        }
        
        guard let lastItem = try store.dequeue() else {
            XCTFail("'Stop.' was not inserted at queue tail")
            return
        }
        XCTAssertEqual(lastItem.identifier, "fifth")
        XCTAssertEqual(lastItem.content as! String, "Stop.")
        
        allItems = try self.sharedStore().peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 0)
    }
    
    func testQueueReplacement() throws {
        let store = KBQueueStore(.inMemory, type: .fifo)
        
        let previousDate = Date().addingTimeInterval(-5 * 60)
        
        try store.enqueue("Hello", withIdentifier: "first")
        try store.enqueue("world", withIdentifier: "second")
        var allItems = try store.peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 2)
        
        try store.enqueue("myself", withIdentifier: "second")
        allItems = try store.peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 2)
        
        guard let firstItem = try store.dequeue() else {
            XCTFail("'Hello' was not inserted at queue 0")
            return
        }
        XCTAssertEqual(firstItem.identifier, "first")
        XCTAssertEqual(firstItem.content as! String, "Hello")
        
        guard let secondItem = try store.dequeue() else {
            XCTFail("'world' was not inserted at queue 1")
            return
        }
        XCTAssertEqual(secondItem.identifier, "second")
        XCTAssertEqual(secondItem.content as! String, "myself")
        
        try store.enqueue("Hello", withIdentifier: "first")
        try store.enqueue("world", withIdentifier: "second")
        try store.insert("other world", withIdentifier: "second", timestamp: previousDate)
        allItems = try store.peekItems(createdWithin: DateInterval.init(start: .distantPast, end: Date()), limit: 10)
        XCTAssertEqual(allItems.count, 2)
        
        guard let firstItem = try store.dequeue() else {
            XCTFail("'other world' was not inserted at queue 0")
            return
        }
        XCTAssertEqual(firstItem.identifier, "second")
        XCTAssertEqual(firstItem.content as! String, "other world")
        
        guard let secondItem = try store.dequeue() else {
            XCTFail("'Hello' was not shifted queue 1")
            return
        }
        XCTAssertEqual(secondItem.identifier, "first")
        XCTAssertEqual(secondItem.content as! String, "Hello")
    }
}
