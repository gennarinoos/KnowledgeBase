//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/22/21.
//

import Foundation


let KnowledgeBaseXPCServiceBundleIdentifier = "com.gf.knowledgebase.storage.service"


#if (!os(macOS)) || DEBUG
// Do not use XPC in DEBUG mode or platforms other than macOS

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
            
            log.info("XPC connection established. %@", self.connection)
    }

    deinit {
        self.connection.invalidate()
    }

    class func mainInstance() -> Self {
        return self.init(name: KnowledgeBaseSQLDefaultIdentifier)
    }
    
    func daemon() -> KBStorageXPCInterface? {
        return self.connection.remoteObjectProxyWithErrorHandler { (error) in
            log.fault("XPC connection error %s", error.localizedDescription)
            } as? KBStorageXPCInterface
    }
    
    @objc static var directory: URL? = {
        let directory: URL, path: URL
        
        do {
            #if CK_IS_MAC
            path = URL(string: StoreLocationForMacOS)!
            #else
            path = try FileManager.default.url(for: .libraryDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
            #endif
        } catch {
            log.fault("Could not find library directory")
            return nil
        }
            
        #if CK_IS_MAC
        directory = path
        #else
        if let mobileUser = getpwnam("mobile") {
            directory = URL(fileURLWithPath: String(cString: mobileUser.pointee.pw_dir)).appendingPathComponent("Library")
        } else {
            directory = path
        }
        #endif
        
        return directory.appendingPathComponent(KnowledgeBaseBundleIdentifier)
    }()
    
    
    //MARK: SELECT
    
    func keys() async throws -> [String] {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        return try await daemon.keys(inStoreWithIdentifier: self.name)
    }
    
    func keys(matching condition: KBGenericCondition) async throws -> [String] {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        let keys = try await daemon.keys(matching: condition, inStoreWithIdentifier: self.name)
        let _ = self // Retain self in the block to keep XPC connection alive
        return keys
    }
    
    func _value(forKey key: String) async throws -> Any? {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        let value = try await daemon.value(forKey: key, inStoreWithIdentifier: self.name)
        let _ = self // Retain self in the block to keep XPC connection alive
        return value
    }
    
    func values() async throws -> [Any] {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        let keysAndValues = try await daemon.keysAndValues(inStoreWithIdentifier: self.name)
        let _ = self // Retain self in the block to keep XPC connection alive
        return keysAndValues.map { $1 }
    }
    
    func values(forKeys keys: [String]) async throws -> [Any?] {
        guard let daemon = self.daemon() else {
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

        let keysAndValues = try await daemon.keysAndValues(forKeysMatching: condition!, inStoreWithIdentifier: self.name)
        let _ = self // Retain self in the block to keep XPC connection alive
        return keysAndValues.map { $1 }
    }
    
    func values(forKeysMatching condition: KBGenericCondition) async throws -> [Any] {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        let keysAndValues = try await daemon.keysAndValues(forKeysMatching: condition, inStoreWithIdentifier: self.name)
        let _ = self // Retain self in the block to keep XPC connection alive
        return keysAndValues.map { $1 }
    }
    
    func dictionaryRepresentation() async throws -> KBJSONObject {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        let keysAndValues = try await daemon.keysAndValues(inStoreWithIdentifier: self.name)
        let _ = self // Retain self in the block to keep XPC connection alive
        return keysAndValues
    }
    
    func dictionaryRepresentation(forKeysMatching condition: KBGenericCondition) async throws -> KBJSONObject {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        let keysAndValues = try await daemon.keysAndValues(forKeysMatching: condition, inStoreWithIdentifier: self.name)
        let _ = self // Retain self in the block to keep XPC connection alive
        return keysAndValues
    }
    
    func triplesComponents(matching condition: KBTripleCondition?) async throws -> [KBTriple] {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        let triples = try await daemon.tripleComponents(matching: condition, inStoreWithIdentifier: self.name)
        let _ = self // Retain self in the block to keep XPC connection alive
        return triples
    }
    
    func verify(path: KBPath) async throws -> Bool {
        log.error("path search in .SQL store not yet supported.") // TODO: Support
        throw KBError.notSupported
    }

    //MARK: INSERT
    
    func _setValue(_ value: Any?,
                   forKey key: String) async throws {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await daemon.save([key: value ?? NSNull()], toStoreWithIdentifier: self.name)
    }

    func writeBatch() -> KBKVStoreWriteBatch {
        return KBSQLXPCWriteBatch(backingStore: self)
    }

    func setWeight(forLinkWithLabel predicate: String,
                   between subjectIdentifier: String,
                   and objectIdentifier: String,
                   toValue newValue: Int) async throws {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await daemon.setWeight(forLinkWithLabel: predicate,
                                   between: subjectIdentifier,
                                   and: objectIdentifier,
                                   toValue: newValue,
                                   inStoreWithIdentifier: self.name)
    }
    
    func increaseWeight(forLinkWithLabel predicate: String,
                        between subjectIdentifier: String,
                        and objectIdentifier: String) async throws -> Int {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        let newWeight = try await daemon.increaseWeight(forLinkWithLabel: predicate,
                                                        between: subjectIdentifier,
                                                        and: objectIdentifier,
                                                        inStoreWithIdentifier: self.name)
        return newWeight
    }
    
    func decreaseWeight(forLinkWithLabel predicate: Label,
                        between subjectIdentifier: Label,
                        and objectIdentifier: Label) async throws -> Int {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        let newWeight = try await daemon.decreaseWeight(forLinkWithLabel: predicate,
                                                        between: subjectIdentifier,
                                                        and: objectIdentifier,
                                                        inStoreWithIdentifier: self.name)
        return newWeight
    }

    //MARK: DELETE
    
    func removeValue(forKey key: String) async throws {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await daemon.removeValue(forKey: key, fromStoreWithIdentifier: self.name)
    }
    
    func removeValues(forKeys keys: [String]) async throws {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await daemon.removeValues(forKeys: keys, fromStoreWithIdentifier: self.name)
    }
    
    func removeValues(matching condition: KBGenericCondition) async throws {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await daemon.removeValues(matching: condition, fromStoreWithIdentifier: self.name)
    }
    
    func removeAllValues() async throws {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await daemon.removeAllValues(fromStoreWithIdentifier: self.name)
    }
    
    func dropLink(withLabel predicate: String,
                  between subjectIdentifier: String,
                  and objectIdentifier: String) async throws {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await daemon.dropLink(withLabel: predicate,
                                  between: subjectIdentifier,
                                  and: objectIdentifier,
                                  inStoreWithIdentifier: self.name)
    }
    
    func dropLinks(withLabel predicate: String?,
                   from subjectIdentifier: String) async throws {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await daemon.dropLinks(withLabel: predicate,
                                   from: subjectIdentifier,
                                   inStoreWithIdentifier: self.name)
    }
    
    func dropLinks(between subjectIdentifier: String,
                   and objectIdentifier: String) async throws {
        guard let daemon = self.daemon() else {
            throw KBError.fatalError("Could not connect to XPC service")
        }
        
        try await daemon.dropLinks(between: subjectIdentifier,
                                   and: objectIdentifier,
                                   inStoreWithIdentifier: self.name)
    }
    
    func disableSyncAndDeleteCloudData() async throws {
        throw KBError.notSupported
    }
}

#endif
