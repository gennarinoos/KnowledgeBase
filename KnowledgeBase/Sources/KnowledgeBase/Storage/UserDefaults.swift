//
//  UserDefaults.swift
//
//
//  Created by Gennaro Frazzingaro on 6/22/21.
//

import Foundation

class KBUserDefaultsBackingStore : KBBackingStore {
    
    private var kv: UserDefaults
    var name: String {
        get { return KnowledgeBaseUserDefaultsIdentifier }
        set(v) {}
    }

    init() {
        log.info("initializing .UserDefaults Store with suite name %@", KnowledgeBaseBundleIdentifier)

        if let defaults = UserDefaults(suiteName: KnowledgeBaseBundleIdentifier) {
            self.kv = defaults
        } else {
            log.fault("Can't initialize defaults with suiteName %@. Using standard user defaults", KnowledgeBaseBundleIdentifier)
            self.kv = UserDefaults()
        }
    }

    internal func synchronize() {
        self.kv.synchronize()
    }
    
    func writeBatch() -> KBKnowledgeStoreWriteBatch {
        return KBUserDefaultsWriteBatch(backingStore: self)
    }

    //MARK: SELECT

    func keys() async throws -> [String] {
        return ((self.kv.dictionaryRepresentation() as NSDictionary).allKeys as! [String])
    }
    
    func keys(matching condition: KBGenericCondition) async throws -> [String] {
        let filteredKeys = ((self.kv.dictionaryRepresentation() as NSDictionary).allKeys.filter {
            k -> Bool in
            return condition.evaluate(on: k)
        })
        return filteredKeys as! [String]
    }
    
    internal func __value(forKey key: String) -> Any? {
        return self.kv.object(forKey: key)
    }
    
    func _value(forKey key: String) async throws -> Any? {
        return self.__value(forKey: key)
    }

    func values() async throws -> [Any] {
        return (self.kv.dictionaryRepresentation() as NSDictionary).allValues
    }
    
    func values(forKeys keys: [String]) async throws -> [Any?] {
        return keys.map { key in self.__value(forKey: key) }
    }
    
    func values(forKeysMatching condition: KBGenericCondition) async throws -> [Any] {
        let filteredKeys = try await self.keys().filter { condition.evaluate(on: $0) }
        return filteredKeys.map { key in self.__value(forKey: key)! }
    }
    
    func dictionaryRepresentation() async throws -> KBJSONObject {
        return self.kv.dictionaryRepresentation()
    }
    
    func dictionaryRepresentation(forKeysMatching condition: KBGenericCondition) async throws -> KBJSONObject {
        return try await self.keys().reduce([:], {
            (dict, k) in
            if condition.evaluate(on: k) {
                var newDict = dict
                newDict[k] = self.__value(forKey: k)!
                return newDict
            }
            return dict
        })
    }
    
    func triplesComponents(matching condition: KBTripleCondition?) async throws -> [KBTriple] {
        log.fault(".UserDefaults store is not meant to store triples")
        throw KBError.notSupported
    }
    
    func verify(path: KBPath) async throws -> Bool {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }

    //MARK: INSERT
    
    func setValue(_ value: Any?, forKey key: String) {
        self.kv.setValue(value, forKey: key)
    }
    
    func increaseWeight(forLinkWithLabel predicate: String,
                        between subjectIdentifier: String,
                        and objectIdentifier: String) async throws -> Int {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func decreaseWeight(forLinkWithLabel predicate: String,
                        between subjectIdentifier: String,
                        and objectIdentifier: String) async throws -> Int {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func setWeight(forLinkWithLabel predicate: String,
                   between subjectIdentifier: String,
                   and objectIdentifier: String,
                   toValue newValue: Int) async throws {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }

    //MARK: - DELETE

    func removeValue(forKey key: String) async throws {
        self.kv.removeObject(forKey: key)
        self.synchronize()
    }
    
    func removeValues(forKeys keys: [String]) async throws {
        for key in keys {
            self.kv.removeObject(forKey: key)
        }
        self.synchronize()
    }

    func removeValues(matching condition: KBGenericCondition) async throws {
        for key in try await self.keys() {
            if condition.evaluate(on: key) {
                self.kv.removeObject(forKey: key)
            }
        }
        self.synchronize()
    }

    func removeAllValues() async throws {
        for key in try await self.keys() {
            self.kv.removeObject(forKey: key)
        }
        self.synchronize()
    }
    
    func dropLink(withLabel predicate: String,
                  between subjectIdentifier: String,
                  and objectIdentifier: String) async throws {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func dropLinks(withLabel predicate: String?,
                   from subjectIdentifier: String) async throws {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func dropLinks(between subjectIdentifier: String,
                   and objectIdentifier: String) async throws {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func disableSyncAndDeleteCloudData() async throws {
        throw KBError.notSupported
    }
}

