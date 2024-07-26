import Foundation

public let KnowledgeBaseXPCServiceBundleIdentifier = "com.gf.knowledgebase.storage.xpc"


#if !os(macOS)
// Use XPC only on macOS

class KBSQLXPCBackingStore : KBSQLBackingStore {
}

#else

class KBSQLXPCBackingStore : KBBackingStore {
    
    var name: String
    let connection: NSXPCConnection

    @objc required init(name: String) {
        self.name = name
        
            self.connection = NSXPCConnection(machServiceName: KnowledgeBaseXPCServiceBundleIdentifier,
                                              options: NSXPCConnection.Options(rawValue: 0))
            
            self.connection.remoteObjectInterface = KnowledgeBaseXPCUtils.KBServiceXPCInterface()
            
            self.connection.interruptionHandler = {
                log.info("XPC connection interrupted")
            }
            self.connection.invalidationHandler = {
                log.info("XPC connection invalidated")
            }
            
            self.connection.resume()
            
            log.info("XPC connection established (\(self.connection, privacy: .public))")
    }

    deinit {
        self.connection.invalidate()
    }

    class func mainInstance() -> Self {
        return self.init(name: KnowledgeBaseSQLDefaultIdentifier)
    }
    
    func xpcService() -> KBStorageXPCProtocol? {
        return self.connection.remoteObjectProxyWithErrorHandler { (error) in
            log.fault("XPC connection error: \(error.localizedDescription, privacy: .public)")
            } as? KBStorageXPCProtocol
    }
    
    
    //MARK: SELECT
    
    func keys() async throws -> [String] {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        return try await service.keys(inStoreWithIdentifier: self.name)
    }
    
    func keys(
        matching condition: KBGenericCondition
    ) async throws -> [String] {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        return try await service.keys(matching: condition, inStoreWithIdentifier: self.name)
    }
    
    func value(
        forKey key: String
    ) async throws -> Any? {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        return try await service.value(forKey: key, inStoreWithIdentifier: self.name)
    }
    
    func values() async throws -> [Any] {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        return try await service.keysAndValues(
            inStoreWithIdentifier: self.name
        )
        .map { $1 }
    }
    
    func values(for keys: [String]) async throws -> [Any?] {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        var condition: KBGenericCondition? = nil
        for keyCondition in keys {
            let curr = KBGenericCondition(.equal, value: keyCondition)
            if let c = condition {
                condition = c.or(curr)
            } else {
                condition = curr
            }
        }
        
        return try await service.keysAndValues(
            forKeysMatching: condition!,
            inStoreWithIdentifier: self.name
        )
        .map { $1 }
    }
    
    func values(forKeysMatching condition: KBGenericCondition) async throws -> [Any?] {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        return try await service.keysAndValues(
            forKeysMatching: condition,
            inStoreWithIdentifier: self.name
        )
        .map { $1 }
    }
    
    func keyValuesAndTimestamps(
        forKeysMatching condition: KBGenericCondition,
        timestampMatching timeCondition: KBTimestampCondition?,
        paginate: KBPaginationOptions?,
        sort: KBSortDirection?
    ) async throws -> [KBKVPairWithTimestamp] {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        return try await service.keyValuesAndTimestamps(
            forKeysMatching: condition,
            timestampMatching: timeCondition,
            inStoreWithIdentifier: self.name,
            paginate: paginate,
            sort: sort?.rawValue
        ).map {
            KBKVPairWithTimestamp(key: $0.key, value: NSNullToNil($0.value), timestamp: $0.timestamp)
        }
    }
    
    func dictionaryRepresentation() async throws -> KBKVPairs {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        return try await service.keysAndValues(inStoreWithIdentifier: self.name)
    }
    
    func dictionaryRepresentation(
        forKeysMatching condition: KBGenericCondition
    ) async throws -> KBKVPairs {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        return try await service.keysAndValues(forKeysMatching: condition, inStoreWithIdentifier: self.name)
    }
    
    func dictionaryRepresentation(
        createdWithin interval: DateInterval,
        paginate: KBPaginationOptions?,
        sort: KBSortDirection
    ) async throws -> [Date: KBKVPairs] {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        return try await service.keysAndValues(
            createdWithin: interval,
            paginate: paginate,
            sort: sort.rawValue,
            inStoreWithIdentifier: self.name
        )
    }
    
    func triplesComponents(
        matching condition: KBTripleCondition?
    ) async throws -> [KBTriple] {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        return try await service.tripleComponents(
            matching: condition,
            inStoreWithIdentifier: self.name
        )
    }
    
    func verify(path: KBPath) async throws -> Bool {
        log.error("path search in .SQL store not yet supported.") // TODO: Support
        throw KBError.notSupported
    }

    //MARK: INSERT
    
    func set(value: Any?, for key: String) async throws {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await service.save(
            [key: value ?? NSNull()],
            toStoreWithIdentifier: self.name
        )
    }

    func writeBatch() -> KBKVStoreWriteBatch {
        return KBSQLXPCWriteBatch(backingStore: self)
    }

    func setWeight(
        forLinkWithLabel predicate: String,
        between subjectIdentifier: String,
        and objectIdentifier: String,
        toValue newValue: Int
    ) async throws {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await service.setWeight(
            forLinkWithLabel: predicate,
            between: subjectIdentifier,
            and: objectIdentifier,
            toValue: newValue,
            inStoreWithIdentifier: self.name
        )
    }
    
    func increaseWeight(
        forLinkWithLabel predicate: String,
        between subjectIdentifier: String,
        and objectIdentifier: String
    ) async throws -> Int {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        let newWeight = try await service.increaseWeight(
            forLinkWithLabel: predicate,
            between: subjectIdentifier,
            and: objectIdentifier,
            inStoreWithIdentifier: self.name
        )
        
        if newWeight == kKBInvalidLinkWeight {
            throw KBError.unexpectedData(newWeight)
        }
        return newWeight
    }
    
    func decreaseWeight(
        forLinkWithLabel predicate: Label,
        between subjectIdentifier: Label,
        and objectIdentifier: Label
    ) async throws -> Int {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        let newWeight = try await service.decreaseWeight(
            forLinkWithLabel: predicate,
            between: subjectIdentifier,
            and: objectIdentifier,
            inStoreWithIdentifier: self.name
        )
        
        if newWeight == kKBInvalidLinkWeight {
            throw KBError.unexpectedData(newWeight)
        }
        return newWeight
    }

    //MARK: DELETE
    
    func removeValue(for key: String) async throws  {
        try await self.removeValues(for: [key])
    }
    
    func removeValues(for keys: [String]) async throws  {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await service.removeValues(
            forKeys: keys,
            fromStoreWithIdentifier: self.name
        )
    }
    
    func removeValues(
        forKeysMatching condition: KBGenericCondition
    ) async throws -> [String] {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        return try await service.removeValues(
            forKeysMatching: condition,
            fromStoreWithIdentifier: self.name
        )
    }
    
    func removeAll() async throws -> [String] {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        return try await service.removeAll(
            fromStoreWithIdentifier: self.name
        )
    }
    
    func dropLink(
        withLabel predicate: Label,
        between subjectIdentifier: Label,
        and objectIdentifier: Label
    ) async throws {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await service.dropLink(
            withLabel: predicate,
            between: subjectIdentifier,
            and: objectIdentifier,
            inStoreWithIdentifier: self.name
        )
    }
    
    func dropLinks(
        withLabel predicate: Label,
        from subjectIdentifier: Label
    ) async throws {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await service.dropLinks(
            withLabel: predicate,
            from: subjectIdentifier,
            inStoreWithIdentifier: self.name
        )
    }
    
    func dropLinks(
        withLabel predicate: Label,
        to objectIdentifier: Label
    ) async throws {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await service.dropLinks(
            withLabel: predicate,
            to: objectIdentifier,
            inStoreWithIdentifier: self.name
        )
    }
    
    func dropLinks(
        between subjectIdentifier: Label,
        and objectIdentifier: Label
    ) async throws {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await service.dropLinks(
            between: subjectIdentifier,
            and: objectIdentifier,
            inStoreWithIdentifier: self.name
        )
    }
    
    func dropLinks(
        fromAndTo entityIdentifier: Label
    ) async throws {
        guard let service = self.xpcService() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await service.dropLinks(
            fromAndTo: entityIdentifier,
            inStoreWithIdentifier: self.name
        )
    }
    
    func disableSyncAndDeleteCloudData() async throws {
        throw KBError.notSupported
    }
}

#endif
