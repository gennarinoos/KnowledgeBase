//
//  SynchedSQL.swift
//
//
//  Created by Gennaro Frazzingaro on 6/28/21.
//

#if DEBUG
// Do not use XPC in DEBUG mode

class KBCloudKitSQLXPCBackingStore : KBCloudKitSQLBackingStore {
}

#else

class KBCloudKitSQLXPCBackingStore : KBSQLXPCBackingStore {
    
    override var name: String {
        get { return KnowledgeBaseSQLSynchedIdentifier }
        set(v) {}
    }
    
    class override func mainInstance() -> Self {
        return self.init(name: KnowledgeBaseSQLSynchedIdentifier)
    }
    
    //MARK: INSERT
    
    override func set(value: Any?, for key: String) async throws {
        self.daemon(errorHandler: completionHandler)?
            .save([key: value ?? NSNull()],
                  toSynchedStoreWithIdentifier: self.name) {
                    (error) in
                    let _ = self // Retain self in the block to keep XPC connection alive
                    completionHandler(error)
        }
    }
    
    override func writeBatch() -> KBKVStoreWriteBatch {
        return KBCloudKitSQLXPCWriteBatch(backingStore: self)
    }
    
    //MARK: DELETE
    
    override func removeValue(for key: String) async throws {
        self.daemon(errorHandler: completionHandler)?
            .removeValue(for: key,
                         fromSynchedStoreWithIdentifier: self.name) {
                            (error) in
                            let _ = self // Retain self in the block to keep XPC connection alive
                            completionHandler(error)
        }
    }
    
    override func removeValues(for keys: [String]) async throws {
        self.daemon(errorHandler: completionHandler)?
            .removeValues(for: keys,
                          fromSynchedStoreWithIdentifier: self.name) {
                            (error) in
                            let _ = self // Retain self in the block to keep XPC connection alive
                            completionHandler(error)
        }
    }
    
    override func removeValues(forKeysMatching condition: KBGenericCondition) async throws {
        self.daemon(errorHandler: completionHandler)?
            .removeValues(forKeysMatching: condition,
                          fromSynchedStoreWithIdentifier: self.name) {
                            (error) in
                            let _ = self // Retain self in the block to keep XPC connection alive
                            completionHandler(error)
        }
    }
    
    override func removeAll() async throws {
        self.daemon(errorHandler: completionHandler)?
            .removeAll(fromSynchedStoreWithIdentifier: self.name) {
                (error) in
                let _ = self // Retain self in the block to keep XPC connection alive
                completionHandler(error)
        }
    }
    
    override func disableSyncAndDeleteCloudData() async throws {
        self.daemon(errorHandler: completionHandler)?
            .disableSyncAndDeleteCloudData() {
                (error) in
                let _ = self // Retain self in the block to keep XPC connection alive
                completionHandler(error)
        }
    }
}

#endif
