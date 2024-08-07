import Foundation

extension KBKVStore {
    
    /**
     Assign a value, or nil, to a specific key in the KVS, asynchronously.
     
     - parameter value: the value
     - parameter key: the key
     
     */
    public func set(
        value: Any?,
        for key: String,
        timestamp: Date? = nil
    ) async throws {
        guard timestamp == nil ||
                self.backingStore is KBInMemoryBackingStore ||
                (
                    self.backingStore is KBSQLBackingStore
                    && !(self.backingStore is KBCloudKitSQLBackingStore)
                    && !(self.backingStore is KBSQLXPCBackingStore) // TODO: Support timestaps in the XPC interface (KBSQLXPCBackingStore)
                )
        else {
            log.error("Saving KVs with a timestamp is only supported with .sql and .inMemory stores")
            throw KBError.notSupported
        }
        
        guard self.supportsSecureCoding(value) else {
            log.error("Trying to save a non NSSecureCoding compliant value (\(String(describing: value))) for key (\(key)")
            throw KBError.unexpectedData(value)
        }
        
        let writeBatch = self.writeBatch()
        if let timestamp {
            writeBatch.set(value: value, for: key, timestamp: timestamp)
        } else {
            writeBatch.set(value: value, for: key)
        }
        
        log.debug("setting value `\(String(describing: value))` for key `\(key)`")
        try await writeBatch.write()
        
        self.delegate?.kvDataDidChange(addedKeys: [key], removedKeys: [])
    }
    
    /**
     Remove a tuple in the KVS, given its key, asynchronously.
     
     - parameter key: the key
     
     */
    public func removeValue(for key: String) async throws {
        try await self.backingStore.removeValue(for: key)
        self.delegate?.kvDataDidChange(addedKeys: [], removedKeys: [key])
    }
    
    /**
     Remove a set of tuples in the KVS, given their keys, asynchronously.
     Blocking version
     
     - parameter keys: the keys
     
     */
    public func removeValues(for keys: [String]) async throws {
        try await self.backingStore.removeValues(for: keys)
        self.delegate?.kvDataDidChange(addedKeys: [], removedKeys: keys)
    }
    
    /**
     Remove a set of tuples in the KVS, matching the condition, asynchronously.
     
     - parameter condition: the condition
     */
    public func removeValues(forKeysMatching condition: KBGenericCondition) async throws -> [String] {
        let keys = try await self.backingStore.removeValues(forKeysMatching: condition)
        self.delegate?.kvDataDidChange(addedKeys: [], removedKeys: keys)
        return keys
    }
    
    /**
     Remove all values in the KVS, asynchronously.
     */
    public func removeAll() async throws -> [String] {
        let removedKeys = try await self.backingStore.removeAll()
        if let s = self as? KBKnowledgeStore {
            s.delegate?.linkedDataDidChange()
        }
        self.delegate?.kvDataDidChange(addedKeys: [], removedKeys: removedKeys)
        return removedKeys
    }
    
    /**
     Disable CloudKit syncing and remove all the data in the cloud, asynchronously.
     */
    public func disableSyncAndDeleteCloudData() async throws {
        try await self.backingStore.disableSyncAndDeleteCloudData()
    }
}
