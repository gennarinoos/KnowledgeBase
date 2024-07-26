//
//  SynchedSQL.swift
//
//
//  Created by Gennaro Frazzingaro on 6/28/21.
//

import Foundation

#if !os(macOS)
// Use XPC only on macOS

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
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await service.save(
            [key: value ?? NSNull()],
            toSynchedStoreWithIdentifier: self.name
        )
    }
    
    override func writeBatch() -> KBKVStoreWriteBatch {
        return KBCloudKitSQLXPCWriteBatch(backingStore: self)
    }
    
    //MARK: DELETE
    
    override func removeValues(for keys: [String]) async throws {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await service.removeValues(
            forKeys: keys,
            fromSynchedStoreWithIdentifier: self.name
        )
    }
    
    override func removeValues(
        forKeysMatching condition: KBGenericCondition
    ) async throws -> [String] {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        return try await service.removeValues(
            forKeysMatching: condition,
            fromSynchedStoreWithIdentifier: self.name
        )
    }
    
    override func removeAll() async throws -> [String] {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        return try await service.removeAll(fromSynchedStoreWithIdentifier: self.name)
    }
    
    override func disableSyncAndDeleteCloudData() async throws {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await service.disableSyncAndDeleteCloudData()
    }
}

#endif
