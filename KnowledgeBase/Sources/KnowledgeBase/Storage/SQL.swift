//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/27/21.
//

import Foundation

public var DatabaseExtension = "db"
private var StoreLocationForMacOS = "/private/var/db";

protocol KBSQLBackingStoreProtocol : KBPersistentBackingStore {
}

extension KBSQLBackingStoreProtocol {
    
    //MARK: SELECT
    
    func keys() async throws -> [String] {
        try self.storeHandler.keys()
    }
    
    func keys(matching condition: KBGenericCondition) async throws -> [String] {
        return try self.storeHandler.keys(matching: condition)
    }
    
    func _value(forKey key: String) async throws -> Any? {
        return try self.storeHandler._values(forKeys: [key]).first!
    }
    
    func values() async throws-> [Any] {
        return try self.storeHandler.values()
    }
    
    func values(forKeys keys: [String]) async throws -> [Any?] {
        return try self.storeHandler._values(forKeys: keys)
    }
    
    func values(forKeysMatching condition: KBGenericCondition) async throws -> [Any] {
        return try self.storeHandler.values(forKeysMatching: condition)
    }
    
    func dictionaryRepresentation() async throws -> KBJSONObject {
        return try self.storeHandler.keysAndValues()
    }
    
    func dictionaryRepresentation(forKeysMatching condition: KBGenericCondition) async throws -> KBJSONObject {
        return try self.storeHandler.keysAndValues(forKeysMatching: condition)
    }
    
    func triplesComponents(matching condition: KBTripleCondition?) async throws -> [KBTriple] {
        return try self.storeHandler.tripleComponents(matching: condition)
    }
    
    func verify(path: KBPath) throws -> Bool {
        return try self.storeHandler.verify(path: path)
    }

    //MARK: INSERT
    
    func setValue(_ value: Any?, forKey key: String) async {
        self.storeHandler.setValue(value, forKey: key)
    }
    
    func setWeight(forLinkWithLabel predicate: String,
                   between subjectIdentifier: String,
                   and objectIdentifier: String,
                   toValue newValue: Int) async throws {
        try self.storeHandler.setWeight(forLinkWithLabel: predicate,
                                                between: subjectIdentifier,
                                                and: objectIdentifier,
                                                toValue: newValue)
    }
    
    func increaseWeight(forLinkWithLabel predicate: String,
                        between subjectIdentifier: String,
                        and objectIdentifier: String) async throws -> Int {
        return try await self.storeHandler.increaseWeight(forLinkWithLabel: predicate,
                                                                 between: subjectIdentifier,
                                                                 and: objectIdentifier)
    }
    
    func decreaseWeight(forLinkWithLabel predicate: Label,
                        between subjectIdentifier: Label,
                        and objectIdentifier: Label) async throws -> Int {
        return try await self.storeHandler.decreaseWeight(forLinkWithLabel: predicate,
                                                                 between: subjectIdentifier,
                                                                 and: objectIdentifier)
    }
    
    //MARK: DELETE
    
    func removeValue(forKey key: String) async throws {
        return try self.storeHandler.removeValue(forKey: key)
    }
    
    func removeValues(forKeys keys: [String]) async throws {
        return try self.storeHandler.removeValues(forKeys: keys)
    }
    
    func removeValues(matching condition: KBGenericCondition) async throws {
        return try self.storeHandler.removeValues(matching: condition)
    }
    
    func removeAllValues() async throws {
        return try self.storeHandler.removeAllValues()
    }
    
    func dropLink(withLabel predicate: String,
                  between subjectIdentifier: String,
                  and objectIdentifier: String) async throws {
        return try self.storeHandler.dropLink(withLabel: predicate,
                                                      between: subjectIdentifier,
                                                      and: objectIdentifier)
    }
    
    func dropLinks(withLabel predicate: String?,
                   from subjectIdentifier: String) async throws {
        return try self.storeHandler.dropLinks(withLabel: predicate,
                                                       from: subjectIdentifier)
    }
    
    func dropLinks(between subjectIdentifier: String,
                   and objectIdentifier: String) async throws {
        return try self.storeHandler.dropLinks(between: subjectIdentifier,
                                                       and: objectIdentifier)
    }
    
    func disableSyncAndDeleteCloudData() async throws {
        throw KBError.notSupported
    }
}


class KBSQLBackingStore : KBSQLBackingStoreProtocol {
    var name: String
    
    // SQL database on disk
    var storeHandler: KBPersistentStoreHandler {
        get {
            return KBPersistentStoreHandler.init(name: self.name)!
        }
    }

    @objc required init(name: String) {
        self.name = name
    }

    class func mainInstance() -> Self {
        return self.init(name: KnowledgeBaseSQLDefaultIdentifier)
    }
    
    @objc static var directory: URL? = {
        let directory: URL, path: URL
        
        do {
#if os(macOS)
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
            
#if os(macOS)
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
}

