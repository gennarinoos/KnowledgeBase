//
//  XPCTestCase.swift
//
//
//  Created by Gennaro Frazzingaro on 8/9/21.
//

import XCTest
@testable import KnowledgeBase

// Use this to locally test the XPC service after running "KnowledgeBaseXPCService"
#if true
class KBXPCTestCase: KVStoreTestCase {
    
    private let internalStore = KBKVStore.store(withName: dbName)!
    
    override func sharedStore() -> KBKVStore {
        internalStore
    }

    deinit {
        if let url = sharedStore().fullURL {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                XCTFail("error deleting database at path \(url)")
            }
        }
    }
}
#endif
