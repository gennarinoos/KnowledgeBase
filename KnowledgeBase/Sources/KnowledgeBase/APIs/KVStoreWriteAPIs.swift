//
//  KVStoreWriteAPIs.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/18/21.
//

import Foundation

public typealias KBObjCActionCompletion = (Error?) -> ()

func KBObjectiveCAPIResultReturningVoid(completionHandler: @escaping (Error?) -> (), _ f: @escaping (@escaping (Swift.Result<Void, Error>) -> ()) -> ()) {
    f { result in
        switch result {
        case .success(): completionHandler(nil)
        case .failure(let err): completionHandler(err)
        }
    }
}


extension KBKVStore {
    
    /**
     Assign a value, or nil, to a specific key in the KVS.
     
     - parameter value: the value
     - parameter key: the key
     - parameter completionHandler: the callback method
     
     */
    open func set(value: Any?, for key: String, completionHandler: @escaping KBActionCompletion) {
        guard self.supportsSecureCoding(value) else {
            log.error("Trying to save a non NSSecureCoding compliant value `%@` for key %@", String(describing: value), key);
            completionHandler(.failure(KBError.unexpectedData(value)))
            return
        }
        
        let writeBatch = self.writeBatch()
        writeBatch.set(value: value, for: key)
        writeBatch.write(completionHandler: completionHandler)
    }
    @objc open func set(value: Any?, for key: String, completionHandler: @escaping KBObjCActionCompletion) {
        KBObjectiveCAPIResultReturningVoid(completionHandler: completionHandler) { c in
            self.set(value: value, for: key, completionHandler: c)
        }
    }
    
    /**
     Remove a tuple in the KVS, given its key.
     
     - parameter key: the key
     - parameter completionHandler: the callback method
     
     */
    open func removeValue(for key: String, completionHandler: @escaping KBActionCompletion) {
        self.backingStore.removeValue(for: key, completionHandler: completionHandler)
    }
    @objc open func removeValue(for key: String, completionHandler: @escaping KBObjCActionCompletion) {
        KBObjectiveCAPIResultReturningVoid(completionHandler: completionHandler) { c in
            self.removeValue(for: key, completionHandler: c)
        }
    }
    
    /**
     Remove a set of tuples in the KVS, given their keys.
     Blocking version
     
     - parameter keys: the keys
     - parameter completionHandler: the callback method
     
     */
    open func removeValues(for keys: [String], completionHandler: @escaping KBActionCompletion) {
        self.backingStore.removeValues(for: keys, completionHandler: completionHandler)
    }
    @objc open func removeValues(for keys: [String], completionHandler: @escaping KBObjCActionCompletion) {
        KBObjectiveCAPIResultReturningVoid(completionHandler: completionHandler) { c in
            self.removeValues(for: keys, completionHandler: c)
        }
    }
    
    /**
     Remove a set of tuples in the KVS, matching the condition.
     
     - parameter condition: the condition
     - parameter completionHandler: the callback method
     */
    open func removeValues(matching condition: KBGenericCondition, completionHandler: @escaping KBActionCompletion) {
        self.backingStore.removeValues(matching: condition, completionHandler: completionHandler)
    }
    @objc func removeValues(matching condition: KBGenericCondition, completionHandler: @escaping KBObjCActionCompletion) {
        KBObjectiveCAPIResultReturningVoid(completionHandler: completionHandler) { c in
            self.removeValues(matching: condition, completionHandler: c)
        }
    }
    
    /**
     Remove all values in the KVS
     
     - parameter completionHandler: the callback method
     
     */
    open func removeAll(completionHandler: @escaping KBActionCompletion) {
        self.backingStore.removeAll(completionHandler: completionHandler)
    }
    @objc func removeAll(completionHandler: @escaping KBObjCActionCompletion) {
        KBObjectiveCAPIResultReturningVoid(completionHandler: completionHandler, self.removeAll(completionHandler:))
    }
    
    /**
     Disable CloudKit syncing and remove all the data in the cloud
     */
    open func disableSyncAndDeleteCloudData(completionHandler: @escaping KBActionCompletion) {
        self.backingStore.disableSyncAndDeleteCloudData(completionHandler: completionHandler)
    }
    @objc open func disableSyncAndDeleteCloudData(completionHandler: @escaping KBObjCActionCompletion) {
        KBObjectiveCAPIResultReturningVoid(completionHandler: completionHandler, self.disableSyncAndDeleteCloudData(completionHandler:))
    }
    
}
