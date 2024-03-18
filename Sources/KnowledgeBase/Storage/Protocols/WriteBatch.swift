//
//  ClassicWriteBatch.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/22/21.
//

import Foundation

//@objc(KBKVStoreWriteBatch)
public protocol KBKVStoreWriteBatch {
    func set(value: Any?, for key: String)
    func set(value: Any?, for key: String, timestamp: Date)
    func set(keysAndValues: [String: Any?])
    func write(completionHandler: @escaping KBActionCompletion)
}

class KBAbstractWriteBatch {
    var buffer: Dictionary<String, (Any?, Date)>
    let backingStore: KBBackingStore
    
    init(backingStore: KBBackingStore) {
        self.buffer = Dictionary<String, (Any?, Date)>()
        self.backingStore = backingStore
    }
    
    @objc func set(value: Any?, for key: String) {
        self.buffer[key] = (value, Date())
    }
    
    @objc func set(value: Any?, for key: String, timestamp: Date) {
        self.buffer[key] = (value, timestamp)
    }
    
    func set(keysAndValues: [String: Any?]) {
        let kvts = keysAndValues.map({ ($0.key, ($0.value, Date()))})
        self.buffer.merge(kvts, uniquingKeysWith: { (_, last) in last })
    }
}

class KBAbstractNoTimestampSQLWriteBatch : KBAbstractWriteBatch, KBKVStoreWriteBatch {
    func write(completionHandler: @escaping KBActionCompletion) {
        guard let backingStore = self.backingStore as? KBSQLBackingStoreProtocol else {
            log.fault("KBSQLWriteBatch should back a KBSQLBackingStoreProtocol")
            completionHandler(.failure(KBError.notSupported))
            return
        }
        
        if self.buffer.count == 0 {
            completionHandler(.success(()))
            return
        }
        
        // Write buffer into the store
        // No need to arbitrate writes through the XPC service for SQL stores (only SQLXPC do)
        var unwrappedBuffer = Dictionary<String, Any>()
        for (k, (v, _)) in self.buffer {
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
    
    @objc override func set(value: Any?, for key: String, timestamp: Date) {
        fatalError("KBUserDefaultsWriteBatch does not support timestamps")
    }
    
    func write(completionHandler: @escaping KBActionCompletion) {
        guard let backingStore = self.backingStore as? KBUserDefaultsBackingStore else {
            log.fault("KBUserDefaultsWriteBatch should back a KBUserDefaultsBackingStore")
            completionHandler(.failure(KBError.notSupported))
            return
        }
        
        if self.buffer.count == 0 {
            completionHandler(.success(()))
            return
        }
        
        // TODO: No need to arbitrate writes through the daemon for Plist stores
        let dispatch = KBTimedDispatch()
        
        for key in self.buffer.keys {
            dispatch.group.enter()
            if let value = self.buffer[key]!.0 {
                backingStore.set(value: value, for: key) { result in
                    switch result {
                    case .failure(let err):
                        dispatch.interrupt(err)
                    case .success():
                        dispatch.group.leave()
                    }
                }
            } else {
                backingStore.removeValue(for: key) { result in
                    switch result {
                    case .failure(let err):
                        dispatch.interrupt(err)
                    case .success():
                        dispatch.group.leave()
                    }
                }
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

class KBSQLWriteBatch : KBAbstractWriteBatch, KBKVStoreWriteBatch {
    
    func write(completionHandler: @escaping KBActionCompletion) {
        guard let backingStore = self.backingStore as? KBSQLBackingStoreProtocol else {
            log.fault("KBSQLWriteBatch should back a KBSQLBackingStoreProtocol")
            completionHandler(.failure(KBError.notSupported))
            return
        }
        
        if self.buffer.count == 0 {
            completionHandler(.success(()))
            return
        }
        
        // Write buffer into the store
        // No need to arbitrate writes through the XPC service for SQL stores (only SQLXPC do)
        var unwrappedBuffer = [KBKVPairWithTimestamp]()
        for (k, (v, t)) in self.buffer {
            unwrappedBuffer.append(
                KBKVPairWithTimestamp(key: k, value: v, timestamp: t)
            )
        }
        
        do {
            try backingStore.sqlHandler.save(keysAndValuesAndTimestamp: unwrappedBuffer)
            self.buffer.removeAll()
            completionHandler(.success(()))
        } catch {
            completionHandler(.failure(error))
        }
    }
}

class KBCloudKitSQLWriteBatch : KBAbstractNoTimestampSQLWriteBatch {
    
    override func write(completionHandler: @escaping KBActionCompletion) {
        super.write(completionHandler: completionHandler)
        // TODO: Trigger iCloud SYNC?
    }
}

class KBSQLXPCWriteBatch : KBAbstractNoTimestampSQLWriteBatch {
}

class KBCloudKitSQLXPCWriteBatch : KBSQLXPCWriteBatch {
}

