//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/22/21.
//

import Foundation

class KBInMemoryBackingStore : KBBackingStore {
    
    var name: String {
        get { return KnowledgeBaseInMemoryIdentifier }
        set(v) {}
    }
    
    internal let inMemoryStoreHandler: KBPersistentStoreHandler
    
    init() {
        self.inMemoryStoreHandler = KBPersistentStoreHandler.inMemoryHandler()!
    }
    
    //MARK: SELECT
    
    func keys() async throws -> [String] {
        try self.inMemoryStoreHandler.keys()
    }
    
    func keys(matching condition: KBGenericCondition) async throws -> [String] {
        return try self.inMemoryStoreHandler.keys(matching: condition)
    }
    
    func value(forKey key: String) async throws -> Any? {
        return try self.inMemoryStoreHandler._values(forKeys: [key]).first!
    }
    
    func values() async throws-> [Any] {
        return try self.inMemoryStoreHandler.values()
    }
    
    func values(forKeys keys: [String]) async throws -> [Any?] {
        return try self.inMemoryStoreHandler._values(forKeys: keys)
    }
    
    func values(forKeysMatching condition: KBGenericCondition) async throws -> [Any] {
        return try self.inMemoryStoreHandler.values(forKeysMatching: condition)
    }
    
    func dictionaryRepresentation() async throws -> KBJSONObject {
        return try self.inMemoryStoreHandler.keysAndValues()
    }
    
    func dictionaryRepresentation(forKeysMatching condition: KBGenericCondition) async throws -> KBJSONObject {
        return try self.inMemoryStoreHandler.keysAndValues(forKeysMatching: condition)
    }
    
    func triplesComponents(matching condition: KBTripleCondition?) async throws -> [KBTriple] {
        return try self.inMemoryStoreHandler.tripleComponents(matching: condition)
    }
    
    func verify(path: KBPath) throws -> Bool {
        return try self.inMemoryStoreHandler.verify(path: path)
    }

    //MARK: INSERT
    
    func setValue(_ value: Any?, forKey key: String) async {
        self.inMemoryStoreHandler.setValue(value, forKey: key)
    }
    
    func writeBatch() -> KBKnowledgeStoreWriteBatch {
        return KBInMemoryWriteBatch(backingStore: self)
    }
    
    func setWeight(forLinkWithLabel predicate: String,
                   between subjectIdentifier: String,
                   and objectIdentifier: String,
                   toValue newValue: Int) async throws {
        try self.inMemoryStoreHandler.setWeight(forLinkWithLabel: predicate,
                                                between: subjectIdentifier,
                                                and: objectIdentifier,
                                                toValue: newValue)
    }
    
    func increaseWeight(forLinkWithLabel predicate: String,
                        between subjectIdentifier: String,
                        and objectIdentifier: String) async throws -> Int {
        return try self.inMemoryStoreHandler.increaseWeight(forLinkWithLabel: predicate,
                                                                 between: subjectIdentifier,
                                                                 and: objectIdentifier)
    }
    
    func decreaseWeight(forLinkWithLabel predicate: Label,
                        between subjectIdentifier: Label,
                        and objectIdentifier: Label) async throws -> Int {
        return try self.inMemoryStoreHandler.decreaseWeight(forLinkWithLabel: predicate,
                                                                 between: subjectIdentifier,
                                                                 and: objectIdentifier)
    }
    
    //MARK: DELETE
    
    func removeValue(forKey key: String) async throws {
        return try self.inMemoryStoreHandler.removeValue(forKey: key)
    }
    
    func removeValues(forKeys keys: [String]) async throws {
        return try self.inMemoryStoreHandler.removeValues(forKeys: keys)
    }
    
    func removeValues(matching condition: KBGenericCondition) async throws {
        return try self.inMemoryStoreHandler.removeValues(matching: condition)
    }
    
    func removeAllValues() async throws {
        return try self.inMemoryStoreHandler.removeAllValues()
    }
    
    func dropLink(withLabel predicate: String,
                  between subjectIdentifier: String,
                  and objectIdentifier: String) async throws {
        return try self.inMemoryStoreHandler.dropLink(withLabel: predicate,
                                                      between: subjectIdentifier,
                                                      and: objectIdentifier)
    }
    
    func dropLinks(withLabel predicate: String?,
                   from subjectIdentifier: String) async throws {
        return try self.inMemoryStoreHandler.dropLinks(withLabel: predicate,
                                                       from: subjectIdentifier)
    }
    
    func dropLinks(between subjectIdentifier: String,
                   and objectIdentifier: String) async throws {
        return try self.inMemoryStoreHandler.dropLinks(between: subjectIdentifier,
                                                       and: objectIdentifier)
    }
    
    func disableSyncAndDeleteCloudData() async throws {
        throw KBError.notSupported
    }
}
