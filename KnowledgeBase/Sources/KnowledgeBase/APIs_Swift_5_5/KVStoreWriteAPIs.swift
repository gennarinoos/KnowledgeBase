//
//  KVStoreWriteAPIs.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/18/21.
//

import Foundation

extension KBKVStore {
    
    /**
     Assign a value, or nil, to a specific key in the KVS, asynchronously.
     
     - parameter value: the value
     - parameter key: the key
     
     */
    @objc open func _setValue(_ value: Any?, forKey key: String) async throws {
        guard self.supportsSecureCoding(value) else {
            log.error("Trying to save a non NSSecureCoding compliant value `%@` for key %@", String(describing: value), key);
            throw KBError.unexpectedData(value)
        }
        
        let writeBatch = self.writeBatch()
        writeBatch.setObject(value, forKey: key)
        try await writeBatch.write()
    }
    
    /**
     Remove a tuple in the KVS, given its key, asynchronously.
     
     - parameter key: the key
     
     */
    @objc open func removeValue(forKey key: String) async throws {
        try await self.backingStore.removeValue(forKey: key)
    }
    
    /**
     Remove a set of tuples in the KVS, given their keys, asynchronously.
     Blocking version
     
     - parameter keys: the keys
     
     */
    @objc open func removeValues(forKeys keys: [String]) async throws {
        try await self.backingStore.removeValues(forKeys: keys)
    }
    
    /**
     Remove a set of tuples in the KVS, matching the condition, asynchronously.
     
     - parameter condition: the condition
     */
    @objc open func removeValues(matching condition: KBGenericCondition) async throws {
        try await self.backingStore.removeValues(matching: condition)
    }
    
    /**
     Remove all values in the KVS, asynchronously.
     */
    @objc open func removeAllValues() async throws {
        try await self.backingStore.removeAllValues()
        if let s = self as? KBKnowledgeStore {
            s.delegate?.linkedDataDidChange()
        }
    }
    
    /**
     Disable CloudKit syncing and remove all the data in the cloud, asynchronously.
     */
    @objc open func disableSyncAndDeleteCloudData() async throws {
        try await self.backingStore.disableSyncAndDeleteCloudData()
    }
}
