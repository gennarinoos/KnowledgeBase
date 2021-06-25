//
//  WriteBatch.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/22/21.
//

import Foundation


// MARK: - KBKnowledgeStoreWriteBatch

@objc(KBKnowledgeStoreWriteBatch)
public protocol KBKnowledgeStoreWriteBatch {
    func setObject(_ object: Any?, forKey: String)
    func write() async throws
}

// MARK: - KBAbstractWriteBatch

class KBAbstractWriteBatch {
    var buffer: Dictionary<String, Any?>
    let backingStore: KBBackingStore
    
    init(backingStore: KBBackingStore) {
        self.buffer = Dictionary<String, Any?>()
        self.backingStore = backingStore
    }
    
    @objc func setObject(_ object: Any?, forKey key: String) {
        self.buffer[key] = object
    }
}

// MARK: - KBInMemoryWriteBatch

class KBInMemoryWriteBatch : KBAbstractWriteBatch, KBKnowledgeStoreWriteBatch {
    
    func write() async throws {
        guard let backingStore = self.backingStore as? KBInMemoryBackingStore else {
            log.fault("KBInMemoryWriteBatch should back a KBInMemoryBackingStore")
            throw KBError.notSupported
        }
        
        // Write buffer into InMemory store
        // No need to arbitrate writes through the daemon for InMemory stores
        var unwrappedBuffer = Dictionary<String, Any>()
        for (k, v) in self.buffer {
            unwrappedBuffer[k] = nilToNSNull(v)
        }
        
        try await backingStore.inMemoryStoreHandler.save(keysAndValues: unwrappedBuffer)
        self.buffer.removeAll()
    }
}

// MARK: - KBUserDefaultsWriteBatch

class KBUserDefaultsWriteBatch : KBAbstractWriteBatch, KBKnowledgeStoreWriteBatch {
    
    func write(completionHandler: @escaping CKActionCompletion) {
        do { try self.write() ; completionHandler(nil) }
        catch { completionHandler(error) }
    }
    
    func write() throws {
        guard let backingStore = self.backingStore as? CKUserDefaultsBackingStore else {
            log.fault("KBUserDefaultsWriteBatch should back a CKUserDefaultsBackingStore")
            throw KBError.notSupported
        }
        
        // No need to arbitrate writes through the daemon for Plist stores
        
        let dispatch = CKTimedDispatch()
        
        for key in self.buffer.keys {
            if let value = self.buffer[key] {
                dispatch.group.enter()
                backingStore.setValue(value, forKey: key, completionHandler: { (error) in
                    if let _ = error {
                        dispatch.interrupt(error!)
                    } else {
                        dispatch.group.leave()
                    }
                })
            }
        }
        
        try dispatch.wait()
        
        backingStore.synchronize()
        self.buffer.removeAll()
    }
}

// MARK: - KBSQLWriteBatch

class KBSQLWriteBatch : KBAbstractWriteBatch, KBKnowledgeStoreWriteBatch {
    
    var queue: DispatchQueue = DispatchQueue(label: "\(KnowledgeBaseBundleIdentifier).SQLWriteBatch", qos: .userInteractive)
    
    func write(completionHandler: @escaping CKActionCompletion) {
        
        guard let backingStore = self.backingStore as? KBSQLBackingStore else {
            log.fault("KBSQLWriteBatch should back a KBSQLBackingStore")
            completionHandler(KBError.notSupported)
            return
        }
        
        // Transform nil to NSNull so that Dictionary<String, Any?>
        // becomes a Dictionary<String, Any!>, and can be converted to an NSDictionary (what the method save below expects)
        var unwrappedBuffer = Dictionary<String, Any>()
        for (k, v) in self.buffer {
            unwrappedBuffer[k] = nilToNSNull(v)
        }
        
            backingStore.daemon(errorHandler: completionHandler)?
                .save(unwrappedBuffer, toStoreWithIdentifier: backingStore.name) {
                (error: Error?) in
                if error == nil {
                    self.buffer.removeAll()
                }
                completionHandler(error)
            }
    }
    
    func write() throws {
        let dispatch = CKTimedDispatch()
        
        weak var welf = self
        self.queue.async {
            welf?.write() { error in
                if let _ = error {
                    dispatch.interrupt(error!)
                } else {
                    dispatch.semaphore.signal()
                }
            }
        }
        
        try dispatch.wait()
    }
}

// MARK: - KBCloudKitWriteBatch

class KBCloudKitWriteBatch : KBSQLWriteBatch {
    
    override func write(completionHandler: @escaping CKActionCompletion) {
        
        #if DEBUG
            super.write(completionHandler: completionHandler)
        #else
            guard let backingStore = self.backingStore as? CKCloudKitBackingStore else {
                log.fault("KBCloudKitWriteBatch should back a CKCloudKitBackingStore")
                completionHandler(KBError.notSupported)
                return
            }
            
            // Transform nil to NSNull so that Dictionary<String, Any?>
            // becomes a Dictionary<String, Any!>, and can be converted to an NSDictionary (what the method save below expects)
            var unwrappedBuffer = Dictionary<String, Any>()
            for (k, v) in self.buffer {
                unwrappedBuffer[k] = nilToNSNull(v)
            }
            
            backingStore.daemon(errorHandler: completionHandler)?
                .save(unwrappedBuffer, toSynchedStoreWithIdentifier: backingStore.name) {
                (error: Error?) in
                if error == nil {
                    self.buffer.removeAll()
                }
                completionHandler(error)
            }
        #endif
    }
}
