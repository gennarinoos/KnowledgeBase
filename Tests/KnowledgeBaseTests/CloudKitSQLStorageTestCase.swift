//
//  CloudKitSQLStorageTests.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/25/21.
//

import XCTest
@testable import KnowledgeBase

class KBCloudKitSQLBackingStoreTests: KVStoreTestCase {
    
    private let internalStore = KBKVStore.defaultSynchedStore()!
    
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
    
    func testDisableAndDeleteCloudSync() {
        sharedStore().disableSyncAndDeleteCloudData() { (result: Swift.Result<Void, Error>) in
            switch result {
            case .failure(let err):
                XCTAssertTrue(err is KnowledgeBase.KBError, "Error is a KBError")
                let error = err as! KnowledgeBase.KBError
                XCTAssertTrue(error.errorCode == KnowledgeBase.KBError.notSupported.errorCode, "error is a KBError.notSupported error")
            case .success():
                XCTFail("Expected error")
            }
        }
    }

    func testSQLNamedPath() {
        let store = sharedStore()
        let sharedKnowledgeBase = KBKnowledgeStore.store(.sqlSynched(""))!
        
        XCTAssert(store.name == KnowledgeBaseSQLSynchedIdentifier, "KnowledgeBase test instance name")

        XCTAssert(sharedKnowledgeBase.name == KnowledgeBaseSQLSynchedIdentifier, "KnowledgeBase shared instance name")
        
        guard let basePath = sharedStore().baseURL else {
            XCTFail()
            return
        }

        let sharedDBPath = basePath.appendingPathComponent(sharedKnowledgeBase.name)
        let testDBPath = basePath.appendingPathComponent(store.name)

        XCTAssert(sharedDBPath == testDBPath, "KnowledgeBase test instance is the shared instance")
        
        print("Test Graph at \(testDBPath)")
        print("Default Graph at \(sharedDBPath)")
        
        XCTAssert(testDBPath.lastPathComponent == KnowledgeBaseSQLSynchedIdentifier, "KnowledgeBase last path component is \(KnowledgeBaseSQLSynchedIdentifier)")
        XCTAssert(sharedDBPath.lastPathComponent == KnowledgeBaseSQLSynchedIdentifier, "KnowledgeBase last path component is \(KnowledgeBaseSQLSynchedIdentifier)")
    }
}

