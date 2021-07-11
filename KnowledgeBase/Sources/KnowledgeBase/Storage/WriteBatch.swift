//
//  WriteBatch.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/22/21.
//

import Foundation

@objc(KBKnowledgeStoreWriteBatch)
public protocol KBKnowledgeStoreWriteBatch {
    func setObject(_ object: Any?, forKey: String)
    func write() async throws
}

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

class KBSQLWriteBatch : KBAbstractWriteBatch, KBKnowledgeStoreWriteBatch {
    
    func write() async throws {
        guard let backingStore = self.backingStore as? KBSQLBackingStoreProtocol else {
            log.fault("KBSQLWriteBatch should back a KBSQLBackingStoreProtocol")
            throw KBError.notSupported
        }
        
        // Write buffer into the store
        // No need to arbitrate writes through the XPC service for SQL stores (only SQLXPC do)
        var unwrappedBuffer = Dictionary<String, Any>()
        for (k, v) in self.buffer {
            unwrappedBuffer[k] = nilToNSNull(v)
        }
        
        try backingStore.storeHandler.save(keysAndValues: unwrappedBuffer)
        self.buffer.removeAll()
    }
}

class KBUserDefaultsWriteBatch : KBAbstractWriteBatch, KBKnowledgeStoreWriteBatch {
    
    func write() async throws {
        guard let backingStore = self.backingStore as? KBUserDefaultsBackingStore else {
            log.fault("KBUserDefaultsWriteBatch should back a KBUserDefaultsBackingStore")
            throw KBError.notSupported
        }
        
        for key in self.buffer.keys {
            if let value = self.buffer[key] {
                backingStore.setValue(value, forKey: key)
            } else {
                backingStore.setValue(nil, forKey: key)
            }
        }
        
        backingStore.synchronize()
        self.buffer.removeAll()
    }
}

class KBCloudKitSQLWriteBatch : KBSQLWriteBatch {
    
    override func write() async throws {
        try await super.write()
        // TODO: Trigger iCloud SYNC?
    }
}


#if os(macOS)

#if DEBUG
// Do not use XPC in DEBUG mode

class KBSQLXPCWriteBatch : KBSQLWriteBatch {
}

#else

class KBSQLXPCWriteBatch : KBAbstractWriteBatch, KBKnowledgeStoreWriteBatch {
    
    var queue: DispatchQueue = DispatchQueue(label: "\(KnowledgeBaseBundleIdentifier).SQLWriteBatch", qos: .userInteractive)
    
    func write() async throws {
        guard let backingStore = self.backingStore as? KBSQLXPCBackingStore else {
            log.fault("KBSQLWriteBatch should back a KBSQLXPCBackingStore")
            throw KBError.notSupported
        }
        
        guard let daemon = backingStore.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        // Transform nil to NSNull so that Dictionary<String, Any?>
        // becomes a Dictionary<String, Any!>, and can be converted to an NSDictionary (what the method save below expects)
        var unwrappedBuffer = Dictionary<String, Any>()
        for (k, v) in self.buffer {
            unwrappedBuffer[k] = nilToNSNull(v)
        }
        
        try await daemon.save(unwrappedBuffer, toStoreWithIdentifier: backingStore.name)
        self.buffer.removeAll()
    }
}
#endif

#if DEBUG
// Do not use XPC in DEBUG mode

class KBCloudKitSQLXPCWriteBatch : KBCloudKitSQLWriteBatch {
}

#else
class KBCloudKitSQLXPCWriteBatch : KBSQLXPCWriteBatch {
    
    override func write() async throws {
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
    }
}

#endif
#endif
