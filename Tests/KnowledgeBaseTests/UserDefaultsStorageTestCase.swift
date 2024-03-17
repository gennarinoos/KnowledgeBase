//
//  UserDefaultsKVStoreTestCase.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/11/21.
//

import XCTest
@testable import KnowledgeBase

class KBUserDefaultsKVStoreTests: KVStoreTestCase {
    
    private let internalStore = KBKVStore.store(.userDefaults)!

    override func sharedStore() -> KBKVStore {
        internalStore
    }
    
    override func cleanup() {
        do {
            let store = self.sharedStore()
            let _ = try store.removeAll()
        } catch {
            XCTFail("\(error)")
        }
    }

    func testUserDefaultsRestored() {
        let userDefaultsStore = KBKnowledgeStore.store(.userDefaults)!
        
        let dictionary = ["key": "value"]
        let key = "KeyToPersist"
        do {
            try sharedStore().set(value: dictionary, for: key)
            let value = try userDefaultsStore.value(for: key)
            XCTAssertNotNil(value)
            XCTAssertNotNil(value as? NSDictionary)

            let userDefaultsStoreCopy = value as! NSDictionary
            XCTAssertEqual(userDefaultsStoreCopy.count, dictionary.count)
            XCTAssertNotNil(userDefaultsStoreCopy["key"] as? String)
            XCTAssertEqual(userDefaultsStoreCopy["key"] as? String, dictionary["key"])
            
            try sharedStore().removeValue(for: key)
            let otherUserDefaultsHandler = KBKnowledgeStore.store(.userDefaults)!
            XCTAssertNotNil(otherUserDefaultsHandler)
            let otherValue = try otherUserDefaultsHandler.value(for: key)
            XCTAssertNil(otherValue)
        } catch {
            XCTFail()
        }
    }

    override func testAllKeyValues() throws {
        try self.sharedStore().set(value: "stringVal", for: "string")
        try self.sharedStore().set(value: 1, for: "int")
        try self.sharedStore().set(value: true, for: "bool")
        try self.sharedStore().set(value: false, for: "NOTbool")
        try self.sharedStore().set(value: ["first", "second"], for: "array")
        try self.sharedStore().set(value: ["first": "first", "second": "second"], for: "dictionary")
        
        let keys = try self.sharedStore()
            .keys(matching: KBGenericCondition(value: true))
            .sorted { $0.compare($1) == .orderedAscending }

        XCTAssertEqual(keys.filter({ ["NOTbool", "array", "bool", "dictionary", "int", "string"].contains($0) }), ["NOTbool", "array", "bool", "dictionary", "int", "string"])
    }
    
    override func testKeyValuesAndTimestampsWithPagination() throws {
        // Not supported
    }
    
    override func testSetValueForKeyUnsecure() throws {
        let key = "NonNSSecureCodingCompliant"
        let emptyString = ""

        for nonSecureValue in [NonNSSecureCodingCompliantStruct(), NonNSSecureCodingCompliantClass()] as [Any] {
            try self.sharedStore().set(value: emptyString, for: key)
            
            let stringValue = try self.sharedStore().value(for: key)
            XCTAssertNotNil(stringValue as? String)
            XCTAssert((stringValue as? String) == emptyString)
            
            try self.sharedStore().set(value: nonSecureValue, for: key)
            let invalidValue = try self.sharedStore().value(for: key)
            XCTAssertNotNil(invalidValue as? String)
            XCTAssert((invalidValue as? String) == emptyString)
            
            do { try self.sharedStore().removeValue(for: key) } catch { XCTFail() }
            let removedValue = try self.sharedStore().value(for: key)
            XCTAssertNil(removedValue)
            
            try self.sharedStore().set(value: nonSecureValue, for: key)
            let invalidValue2 = try self.sharedStore().value(for: key)
            XCTAssertNil(invalidValue2)
        }
    }

    func testPerformances() {
        measure {
            do {
                try self.testWriteBatch()
            } catch {
                XCTFail("\(error)")
            }
        }
    }
}
