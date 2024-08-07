import XCTest
@testable import KnowledgeBase

class KBUserDefaultsKVStoreTests: KVStoreTestCase {
    
    private let internalStore = KBKVStore.store(.userDefaults)!

    override func sharedStore() -> KBKVStore {
        internalStore
    }
    
    override func cleanup() async throws {
        let store = self.sharedStore()
        let _ = try await store.removeAll()
    }

    func testUserDefaultsRestored() async {
        let userDefaultsStore = KBKnowledgeStore.store(.userDefaults)!
        
        let dictionary = ["key": "value"]
        let key = "KeyToPersist"
        do {
            try await sharedStore().set(value: dictionary, for: key)
            let value = try await userDefaultsStore.value(for: key)
            XCTAssertNotNil(value)
            XCTAssertNotNil(value as? NSDictionary)

            let userDefaultsStoreCopy = value as! NSDictionary
            XCTAssertEqual(userDefaultsStoreCopy.count, dictionary.count)
            XCTAssertNotNil(userDefaultsStoreCopy["key"] as? String)
            XCTAssertEqual(userDefaultsStoreCopy["key"] as? String, dictionary["key"])
            
            try await sharedStore().removeValue(for: key)
            let otherUserDefaultsHandler = KBKnowledgeStore.store(.userDefaults)!
            XCTAssertNotNil(otherUserDefaultsHandler)
            let otherValue = try await otherUserDefaultsHandler.value(for: key)
            XCTAssertNil(otherValue)
        } catch {
            XCTFail()
        }
    }

    override func testAllKeyValues() async throws {
        try await self.sharedStore().set(value: "stringVal", for: "string")
        try await self.sharedStore().set(value: 1, for: "int")
        try await self.sharedStore().set(value: true, for: "bool")
        try await self.sharedStore().set(value: false, for: "NOTbool")
        try await self.sharedStore().set(value: ["first", "second"], for: "array")
        try await self.sharedStore().set(value: ["first": "first", "second": "second"], for: "dictionary")
        
        let keys = try await self.sharedStore()
            .keys(matching: KBGenericCondition(value: true))
            .sorted { $0.compare($1) == .orderedAscending }

        XCTAssertEqual(keys.filter({ ["NOTbool", "array", "bool", "dictionary", "int", "string"].contains($0) }), ["NOTbool", "array", "bool", "dictionary", "int", "string"])
    }
    
    override func testKeyValuesAndTimestampsWithPagination() async throws {
        // Not supported
    }
    
    override func testKeyValuesAndTimestampsWithTimeConditions() async throws {
        // Not supported
    }
    
    override func testPaginateSortLargerKVS() async throws {
        // Not supported
    }
}
