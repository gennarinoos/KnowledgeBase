//
//  SyncStoreWriteAPI.swift
//
//
//  Created by Gennaro Frazzingaro on 7/20/21.
//

import Foundation

extension KBKVStoreWriteBatch {
    func write() throws {
        try KBSyncMethodReturningVoid(execute: self.write(completionHandler:))
    }
}

extension KBSyncKVStore {
    /**
     Assign a value, or nil, to a specific key in the KVS.
     Blocking version.
     
     - parameter value: the value
     - parameter key: the key
     */
    open func _setValue(_ value: Any?, forKey key: String) throws {
        guard self.supportsSecureCoding(value) else {
            log.error("Trying to save a non NSSecureCoding compliant value `%@` for key %@", String(describing: value), key);
            return
        }
        
        let writeBatch = self.writeBatch()
        writeBatch.setObject(value, forKey: key)
        log.info("setting value setting value=%@ for key=%@", String(describing: value), key)
        try KBSyncMethodReturningVoid(execute:writeBatch.write)
    }
    
    /**
     Remove a tuple in the KVS, given its key.
     Blocking version.
     
     - parameter key: the key
     */
    @objc open func removeValue(forKey key: String) throws {
        try KBSyncMethodReturningVoid { c in
            self.removeValue(forKey: key, completionHandler: c)
        }
    }
    
    /**
     Remove a set of tuples in the KVS, given their keys.
     Blocking version
     
     - parameter keys: the keys
     */
    @objc open func removeValues(forKeys keys: [String]) throws {
        try KBSyncMethodReturningVoid { c in
            self.removeValues(forKeys: keys, completionHandler: c)
        }
    }
    
    /**
     Remove a set of tuples in the KVS, matching the condition.
     Blocking version
     
     - parameter condition: the condition
     */
    @objc open func removeValues(matching condition: KBGenericCondition) throws {
        try KBSyncMethodReturningVoid { c in
            self.removeValues(matching: condition, completionHandler: c)
        }
    }
    
    /**
     Remove all values in the KVS
     */
    @objc open func removeAllValues() throws {
        try KBSyncMethodReturningVoid(execute: self.removeAllValues)
    }
}

extension KBSyncKnowledgeStore {
    
    /**
     Remove the entity with a certain identifier.
     WARN: This will remove all the connections to this entity in the graph.
     Blocking version.
     
     - parameter identifier: the identifier
     */
    @objc open func removeEntity(_ identifier: Label) throws {
        try KBSyncMethodReturningVoid { c in
            self.removeEntity(identifier, completionHandler: c)
        }
    }
}
