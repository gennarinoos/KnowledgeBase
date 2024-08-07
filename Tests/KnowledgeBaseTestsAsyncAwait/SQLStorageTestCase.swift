import XCTest
@testable import KnowledgeBase

let dbName = "relational-test"

class KBSQLBackingStoreTests: KVStoreTestCase {
    
    private let internalStore = KBKVStore.store(.sql(dbName))!
    
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

    func testSQLNamedPath() async throws {
        let store = sharedStore()
        let sharedKnowledgeBase = KBKnowledgeStore.store(.sql(""))!
        
        XCTAssert(store.name == dbName, "KnowledgeBase test instance name")

        XCTAssert(sharedKnowledgeBase.name == KnowledgeBaseSQLDefaultIdentifier, "KnowledgeBase shared instance name")
        
        guard let directory = sharedStore().baseURL else {
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
        
        
        let customName = "com.gf.test"
        let customStore = KBKnowledgeStore.store(.sql(customName))!
        
        XCTAssertNotNil(customStore)
        XCTAssertNotNil(customStore.name)
        XCTAssertNotNil(customStore.fullURL)
        
        XCTAssert(customStore.name == customName)
        
        let customStoreExpectedPath = directory
            .appendingPathComponent(customStore.name)
            .appendingPathExtension(DatabaseExtension)

        XCTAssert(customStoreExpectedPath == customStore.fullURL)
        
        do { let _ = try await customStore.keys() }
        catch { XCTFail() }
        
        do { try FileManager.default.removeItem(at: customStore.fullURL!) }
        catch { XCTFail() }
    }
    
    func testFileOnDisk() async throws {
        let newStore = KBKVStore.store(withName: UUID().uuidString)!
        XCTAssertNotNil(newStore)
        XCTAssertNotNil(newStore.fullURL)
        
        let _ = try await newStore.keys()
        
        XCTAssert(FileManager.default.fileExists(atPath: newStore.fullURL!.path), "Database file at path \(newStore.fullURL!)")
        
        try FileManager.default.removeItem(at: newStore.fullURL!)
        
        let dottedName = "com.gf.test"
        let customStore = KBKnowledgeStore.store(.sql(dottedName))!
        
        XCTAssertNotNil(customStore)
        XCTAssertNotNil(customStore.fullURL)
        
        let _ = try await customStore.keys()
        
        XCTAssert(FileManager.default.fileExists(atPath: customStore.fullURL!.path), "Database file at path \(customStore.fullURL!)")
        
        try FileManager.default.removeItem(at: customStore.fullURL!)
    }
    
    func testInitWithExistingDB() {
        let url = URL(fileURLWithPath: "~/Library/com.gf.framework.knowledgebase/test.db")
        let assetStore = KBKVStore(existingDB: url)!
        
        XCTAssert(assetStore.baseURL?.lastPathComponent == "com.gf.framework.knowledgebase")
        XCTAssert(assetStore.fullURL?.lastPathComponent == "test.db")
    }
}
