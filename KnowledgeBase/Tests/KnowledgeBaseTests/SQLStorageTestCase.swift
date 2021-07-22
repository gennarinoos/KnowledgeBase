//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/11/21.
//

import XCTest
@testable import KnowledgeBase

let dbName = "relational-test"

class KBSQLBackingStoreTests: KVStoreTestCase {
    
    private static let _sharedStore = KBSyncKnowledgeStore.store(.sql(dbName))
    
    override func sharedStore() -> KBSyncKVStore {
        return KBSQLBackingStoreTests._sharedStore
    }

    deinit {
        if let path = KBSQLBackingStoreTests._sharedStore.filePath {
            do {
                try FileManager.default.removeItem(at: path)
            } catch {
                XCTFail("error deleting database at path \(path)")
            }
        }
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSQLNamedPath() {
        let store = KBSQLBackingStoreTests._sharedStore
        let sharedKnowledgeBase = KBKnowledgeStore.store(.sql(""))
        
        XCTAssert(store.name == dbName, "KnowledgeBase test instance name")

        XCTAssert(sharedKnowledgeBase.name == KnowledgeBaseSQLDefaultIdentifier, "KnowledgeBase shared instance name")
        
        guard let directory = KBKnowledgeStore.directory() else {
            XCTFail()
            return
        }

        let sharedDBPath = directory
            .appendingPathComponent(sharedKnowledgeBase.name)
            .appendingPathExtension(DatabaseExtension)
        
        let testDBPath = directory
            .appendingPathComponent(store.name)
            .appendingPathExtension(DatabaseExtension)

        XCTAssert(sharedDBPath != testDBPath, "KnowledgeBase test and shared instance are separate")
        
        print("Test Graph at \(testDBPath)")
        print("Default Graph at \(sharedDBPath)")

        XCTAssert(testDBPath.lastPathComponent == "\(dbName).\(DatabaseExtension)", "KnowledgeBase last path component is \(testDBPath.lastPathComponent)")

        XCTAssert(sharedDBPath.lastPathComponent == "\(KnowledgeBaseSQLDefaultIdentifier).\(DatabaseExtension)",
            "KnowledgeBase last path component is \(KnowledgeBaseSQLDefaultIdentifier)")
        
        
        let customName = "com.apple.siri.test"
        let customStore = KBKnowledgeStore.store(.sql(customName))
        
        XCTAssertNotNil(customStore)
        XCTAssertNotNil(customStore.name)
        XCTAssertNotNil(customStore.filePath)
        
        XCTAssert(customStore.name == customName)
        
        let customStoreExpectedPath = directory
            .appendingPathComponent(customStore.name)
            .appendingPathExtension(DatabaseExtension)

        XCTAssert(customStoreExpectedPath == customStore.filePath)
        
        do { try FileManager.default.removeItem(at: customStore.filePath!) }
        catch { XCTFail() }
    }
    
    func testFileOnDisk() {
        let newStore = KBKnowledgeStore.store(withName: UUID().uuidString)
        XCTAssertNotNil(newStore)
        XCTAssertNotNil(newStore.filePath)
        
        XCTAssert(FileManager.default.fileExists(atPath: newStore.filePath!.path), "Database file at path \(newStore.filePath!)")
        
        do { try FileManager.default.removeItem(at: newStore.filePath!) }
        catch { XCTFail() }
        
        let dottedName = "com.apple.siri.test"
        let customStore = KBKnowledgeStore.store(.sql(dottedName))
        
        XCTAssertNotNil(customStore)
        XCTAssertNotNil(customStore.filePath)
        
        XCTAssert(FileManager.default.fileExists(atPath: customStore.filePath!.path), "Database file at path \(customStore.filePath!)")
        
        do { try FileManager.default.removeItem(at: customStore.filePath!) }
        catch { XCTFail() }
    }
}

