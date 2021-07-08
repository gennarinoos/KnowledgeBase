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
    
    override func setValue(_ value: Any?, forKey key: String) async throws {
        self.daemon(errorHandler: completionHandler)?
            .save([key: value ?? NSNull()],
                  toSynchedStoreWithIdentifier: self.name) {
                    (error) in
                    let _ = self // Retain self in the block to keep XPC connection alive
                    completionHandler(error)
        }
    }
    
    override func writeBatch() -> KBKnowledgeStoreWriteBatch {
        return KBCloudKitSQLXPCWriteBatch(backingStore: self)
    }
    
    //MARK: DELETE
    
    override func removeValue(forKey key: String) async throws {
        self.daemon(errorHandler: completionHandler)?
            .removeValue(forKey: key,
                         fromSynchedStoreWithIdentifier: self.name) {
                            (error) in
                            let _ = self // Retain self in the block to keep XPC connection alive
                            completionHandler(error)
        }
    }
    
    override func removeValues(forKeys keys: [String]) async throws {
        self.daemon(errorHandler: completionHandler)?
            .removeValues(forKeys: keys,
                          fromSynchedStoreWithIdentifier: self.name) {
                            (error) in
                            let _ = self // Retain self in the block to keep XPC connection alive
                            completionHandler(error)
        }
    }
    
    override func removeValues(matching condition: KBGenericCondition) async throws {
        self.daemon(errorHandler: completionHandler)?
            .removeValues(matching: condition,
                          fromSynchedStoreWithIdentifier: self.name) {
                            (error) in
                            let _ = self // Retain self in the block to keep XPC connection alive
                            completionHandler(error)
        }
    }
    
    override func removeAllValues() async throws {
        self.daemon(errorHandler: completionHandler)?
            .removeAllValues(fromSynchedStoreWithIdentifier: self.name) {
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
