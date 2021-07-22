//
//  UserDefaultsKVStoreTestCase.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/11/21.
//

import XCTest
@testable import KnowledgeBase

class KBUserDefaultsKVStoreTests: KVStoreTestCase {

    private static let _sharedStore = KBSyncKnowledgeStore.store(.userDefaults)
    
    override func sharedStore() -> KBSyncKVStore {
        return KBUserDefaultsKVStoreTests._sharedStore
    }

    override func testWriteBatch() throws {
        try super.testWriteBatch()
    }

    func testUserDefaultsRestored() {
        let userDefaultsStore = KBKnowledgeStore.store(.userDefaults)
        
        let dictionary = ["key": "value"]
        let key = "KeyToPersist"
        do {
            try KBUserDefaultsKVStoreTests._sharedStore._setValue(dictionary, forKey: key)
            let value = try userDefaultsStore._value(forKey: key)
            XCTAssertNotNil(value)
            XCTAssertNotNil(value as? NSDictionary)

            let userDefaultsStoreCopy = value as! NSDictionary
            XCTAssertEqual(userDefaultsStoreCopy.count, dictionary.count)
            XCTAssertNotNil(userDefaultsStoreCopy["key"] as? String)
            XCTAssertEqual(userDefaultsStoreCopy["key"] as? String, dictionary["key"])
            
            try KBUserDefaultsKVStoreTests._sharedStore.removeValue(forKey: key)
            let otherUserDefaultsHandler = KBKnowledgeStore.store(.userDefaults)
            XCTAssertNotNil(otherUserDefaultsHandler)
            let otherValue = try otherUserDefaultsHandler._value(forKey: key)
            XCTAssertNil(otherValue)
        } catch {
            XCTFail()
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
