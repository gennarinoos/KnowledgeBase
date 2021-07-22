//
//  ClassicWriteBatch.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/22/21.
//

import Foundation

//@objc(KBKVStoreWriteBatch)
public protocol KBKVStoreWriteBatch {
    func setObject(_ object: Any?, forKey: String)
    func write(completionHandler: @escaping KBActionCompletion)
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

class KBSQLWriteBatch : KBAbstractWriteBatch, KBKVStoreWriteBatch {
    
    func write(completionHandler: @escaping KBActionCompletion) {
        guard let backingStore = self.backingStore as? KBSQLBackingStoreProtocol else {
            log.fault("KBSQLWriteBatch should back a KBSQLBackingStoreProtocol")
            completionHandler(.failure(KBError.notSupported))
            return
        }
        
        // Write buffer into the store
        // No need to arbitrate writes through the XPC service for SQL stores (only SQLXPC do)
        var unwrappedBuffer = Dictionary<String, Any>()
        for (k, v) in self.buffer {
            unwrappedBuffer[k] = nilToNSNull(v)
        }
        
        do {
            try backingStore.sqlHandler.save(keysAndValues: unwrappedBuffer)
            self.buffer.removeAll()
            completionHandler(.success(()))
        } catch {
            completionHandler(.failure(error))
        }
    }
}

class KBUserDefaultsWriteBatch : KBAbstractWriteBatch, KBKVStoreWriteBatch {
    
    func write(completionHandler: @escaping KBActionCompletion) {
        guard let backingStore = self.backingStore as? KBUserDefaultsBackingStore else {
            log.fault("KBUserDefaultsWriteBatch should back a KBUserDefaultsBackingStore")
            completionHandler(.failure(KBError.notSupported))
            return
        }
        
        // TODO: No need to arbitrate writes through the daemon for Plist stores
        let dispatch = KBTimedDispatch()
        
        for key in self.buffer.keys {
            if let value = self.buffer[key] {
                dispatch.group.enter()
                backingStore._setValue(value, forKey: key, completionHandler: { result in
                    switch result {
                    case .failure(let err):
                        dispatch.interrupt(err)
                    case .success():
                        dispatch.group.leave()
                    }
                })
            }
        }
        
        do {
            try dispatch.wait()
        } catch {
            completionHandler(.failure(error))
        }
        
        backingStore.synchronize()
        self.buffer.removeAll()
        
        completionHandler(.success(()))
    }
}

class KBCloudKitSQLWriteBatch : KBSQLWriteBatch {
    
    override func write(completionHandler: @escaping KBActionCompletion) {
        super.write(completionHandler: completionHandler)
        // TODO: Trigger iCloud SYNC?
    }
}


#if os(macOS)

#if DEBUG
// Do not use XPC in DEBUG mode

class KBSQLXPCWriteBatch : KBSQLWriteBatch {
}

#else

class KBSQLXPCWriteBatch : KBAbstractWriteBatch, KBKVStoreWriteBatch {
    
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
        
        try await super.write()
    }
}

#endif
#endif
