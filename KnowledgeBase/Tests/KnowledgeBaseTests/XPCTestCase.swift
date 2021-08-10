//
//  XPCTestCase.swift
//
//
//  Created by Gennaro Frazzingaro on 8/9/21.
//

import XCTest
@testable import KnowledgeBase

// Use this to locally test the XPC service after running "KnowledgeBaseXPCService"
#if false
class KBXPCTestCase: KVStoreTestCase {
    
    private static let _sharedStore = KBKVStore.store(withName: dbName)
    
    override func sharedStore() -> KBKVStore {
        return KBXPCTestCase._sharedStore
    }

    deinit {
        if let url = KBXPCTestCase._sharedStore.dbURL {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                XCTFail("error deleting database at path \(url)")
            }
        }
    }
}
#endif
