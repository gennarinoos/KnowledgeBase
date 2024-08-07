import Foundation

public protocol KBKVStoreWriteBatch {
    func set(value: Any?, for key: String)
    func set(value: Any?, for key: String, timestamp: Date)
    func set(keysAndValues: [String: Any?])
    func write() async throws
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
        
        try backingStore.sqlHandler.save(keysAndValues: unwrappedBuffer)
        self.buffer.removeAll()
    }
}

class KBUserDefaultsWriteBatch : KBAbstractWriteBatch, KBKVStoreWriteBatch {
    
    override func set(value: Any?, for key: String, timestamp: Date) {
        fatalError("KBUserDefaultsWriteBatch does not support timestamps")
    }
    
    func write() async throws {
        guard let backingStore = self.backingStore as? KBUserDefaultsBackingStore else {
            log.fault("KBUserDefaultsWriteBatch should back a KBUserDefaultsBackingStore")
            throw KBError.notSupported
        }
        
        for key in self.buffer.keys {
            if let value = self.buffer[key]!.0 {
                try await backingStore.set(value: value, for: key)
            }
            else {
                try await backingStore.removeValue(for: key)
            }
        }
        
        backingStore.synchronize()
        self.buffer.removeAll()
    }
}

class KBSQLWriteBatch : KBAbstractWriteBatch, KBKVStoreWriteBatch {
    
    func write() async throws {
        guard let backingStore = self.backingStore as? KBSQLBackingStoreProtocol else {
            log.fault("KBSQLWriteBatch should back a KBSQLBackingStoreProtocol")
            throw KBError.notSupported
        }
        
        // Write buffer into the store
        // No need to arbitrate writes through the XPC service for SQL stores (only SQLXPC do)
        var unwrappedBuffer = [KBKVPairWithTimestamp]()
        for (k, (v, t)) in self.buffer {
            unwrappedBuffer.append(
                KBKVPairWithTimestamp(key: k, value: nilToNSNull(v), timestamp: t)
            )
        }
        
        try backingStore.sqlHandler.save(keysAndValuesAndTimestamp: unwrappedBuffer)
        self.buffer.removeAll()
    }
}

class KBCloudKitSQLWriteBatch : KBSQLWriteBatch {
    override func write() async throws {
        try await super.write()
        // TODO: Trigger iCloud SYNC?
    }
}

#if false // os(macOS)
// Use XPC only on macOS
class KBSQLXPCWriteBatch : KBAbstractWriteBatch, KBKVStoreWriteBatch {
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

class KBCloudKitSQLXPCWriteBatch : KBSQLXPCWriteBatch {}

#else

class KBSQLXPCWriteBatch : KBAbstractNoTimestampSQLWriteBatch {
}

class KBCloudKitSQLXPCWriteBatch : KBSQLXPCWriteBatch {
}

#endif
