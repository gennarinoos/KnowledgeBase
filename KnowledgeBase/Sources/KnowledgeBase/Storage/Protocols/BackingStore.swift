//
//  BackingStore.swift
//
//
//  Created by Gennaro Frazzingaro on 6/19/21.
//

#if HAS_ASYNC_AWAIT // No need for the synchronous version with Swift 5.5 or greater.
#else
typealias KBBackingStoreProtocol = KBAsynchronousBackingStore & KBSynchronousBackingStore
#endif


protocol KBAsynchronousBackingStore {
    
    // MARK: KVStore
    func keys(completionHandler: @escaping (Swift.Result<[String], Error>) -> ())
    func keys(matching: KBGenericCondition, completionHandler: @escaping (Swift.Result<[String], Error>) -> ())
    func _value(forKey key: String, completionHandler: @escaping (Swift.Result<Any?, Error>) -> ())
    func values(completionHandler: @escaping (Swift.Result<[Any], Error>) -> ())
    func values(forKeys keys: [String], completionHandler: @escaping (Swift.Result<[Any?], Error>) -> ())
    func values(forKeysMatching: KBGenericCondition, completionHandler: @escaping (Swift.Result<[Any?], Error>) -> ())
    func dictionaryRepresentation(completionHandler: @escaping (Swift.Result<KBJSONObject, Error>) -> ())
    func dictionaryRepresentation(forKeysMatching: KBGenericCondition,
                                  completionHandler: @escaping (Swift.Result<KBJSONObject, Error>) -> ())
    func _setValue(_: Any?, forKey: String, completionHandler: @escaping KBActionCompletion)
    func removeValue(forKey key: String, completionHandler: @escaping KBActionCompletion)
    func removeValues(forKeys keys: [String], completionHandler: @escaping KBActionCompletion)
    func removeValues(matching condition: KBGenericCondition, completionHandler: @escaping KBActionCompletion)
    func removeAllValues(completionHandler: @escaping KBActionCompletion)
    
    // MARK: KnowledgeStore
    func triplesComponents(matching condition: KBTripleCondition?,
                           completionHandler: @escaping (Swift.Result<[KBTriple], Error>) -> ())
    func verify(path: KBPath, completionHandler: @escaping (Swift.Result<Bool, Error>) -> ())
    func setWeight(forLinkWithLabel predicate: String,
                   between subjectIdentifier: String,
                   and objectIdentifier: String,
                   toValue newValue: Int,
                   completionHandler: @escaping KBActionCompletion)
    func increaseWeight(forLinkWithLabel predicate: String,
                        between subjectIdentifier: String,
                        and objectIdentifier: String,
                        completionHandler: @escaping (Swift.Result<Int, Error>) -> ())
    func decreaseWeight(forLinkWithLabel predicate: Label,
                        between subjectIdentifier: Label,
                        and objectIdentifier: Label,
                        completionHandler: @escaping (Swift.Result<Int, Error>) -> ())
    func dropLink(withLabel predicate: String,
                  between subjectIdentifier: String,
                  and objectIdentifier: String,
                  completionHandler: @escaping KBActionCompletion)
    func dropLinks(withLabel predicate: String?,
                   from subjectIdentifier: String,
                   completionHandler: @escaping KBActionCompletion)
    func dropLinks(between subjectIdentifier: String,
                   and objectIdentifier: String,
                   completionHandler: @escaping KBActionCompletion)
    
    // MARK: Cloud sync
    func disableSyncAndDeleteCloudData(completionHandler: @escaping KBActionCompletion)
}

/**
  Blocking API for the KBAsynchronousBackingStore.
  Uses semaphores to synchronize the threads.
 */
protocol KBSynchronousBackingStore : KBAsynchronousBackingStore {
    
    // MARK: KVStore
    func keys() throws -> [String]
    func keys(matching: KBGenericCondition) throws -> [String]
    func _value(forKey key: String) throws -> Any?
    func values() throws -> [Any]
    func values(forKeys keys: [String]) throws -> [Any?]
    func values(forKeysMatching: KBGenericCondition) throws -> [Any?]
    func dictionaryRepresentation() throws -> KBJSONObject
    func dictionaryRepresentation(forKeysMatching: KBGenericCondition) throws -> KBJSONObject
    func _setValue(_: Any?, forKey: String) throws
    func removeValue(forKey key: String) throws
    func removeValues(forKeys keys: [String]) throws
    func removeValues(matching condition: KBGenericCondition) throws
    func removeAllValues() throws
    
    // MARK: KnowledgeStore
    func triplesComponents(matching condition: KBTripleCondition?) throws -> [KBTriple]
    func verify(path: KBPath) throws -> Bool
    func setWeight(forLinkWithLabel predicate: String,
                   between subjectIdentifier: String,
                   and objectIdentifier: String,
                   toValue newValue: Int) throws
    func increaseWeight(forLinkWithLabel predicate: String,
                        between subjectIdentifier: String,
                        and objectIdentifier: String) throws -> Int
    func decreaseWeight(forLinkWithLabel predicate: Label,
                        between subjectIdentifier: Label,
                        and objectIdentifier: Label) throws -> Int
    func dropLink(withLabel predicate: String,
                  between subjectIdentifier: String,
                  and objectIdentifier: String) throws
    func dropLinks(withLabel predicate: String?,
                   from subjectIdentifier: String) throws
    func dropLinks(between subjectIdentifier: String,
                   and objectIdentifier: String) throws
    
    // MARK: Cloud sync
    func disableSyncAndDeleteCloudData() throws
}


/**
 * This protocol defaults the synchronous methods to call the asynchronous one.
 */
extension KBSynchronousBackingStore {
    
    func keys() throws -> [String] {
        return try KBSyncMethodReturningInitiable(execute: self.keys)
    }
    
    func keys(matching condition: KBGenericCondition) throws -> [String] {
        return try KBSyncMethodReturningInitiable {
            (completionHandler) in
            self.keys(matching: condition, completionHandler: completionHandler)
        }
    }
    
    func _value(forKey key: String) throws -> Any? {
        return try KBSyncMethodReturningInitiable { c in
            self._value(forKey: key, completionHandler: c)
        }
    }
    
    func _setValue(_ value: Any?, forKey key: String) throws {
        return try KBSyncMethodReturningVoid { c in
            self._setValue(value, forKey: key, completionHandler: c)
        }
    }
    
    func values() throws -> [Any] {
        return try KBSyncMethodReturningInitiable(execute: self.values)
    }
    
    func values(forKeys keys: [String]) throws -> [Any?] {
        return try KBSyncMethodReturningInitiable { c in
            self.values(forKeys: keys, completionHandler: c)
        }
    }
    
    func values(forKeysMatching condition: KBGenericCondition) throws -> [Any?] {
        return try KBSyncMethodReturningInitiable {
            (completionHandler) in
            self.values(forKeysMatching: condition, completionHandler: completionHandler)
        }
    }
    
    func dictionaryRepresentation() throws -> KBJSONObject {
        return try KBSyncMethodReturningInitiable(execute: self.dictionaryRepresentation)
    }
    
    func dictionaryRepresentation(forKeysMatching condition: KBGenericCondition) throws -> KBJSONObject {
        return try KBSyncMethodReturningInitiable {
            (completionHandler) in
            self.dictionaryRepresentation(forKeysMatching: condition, completionHandler: completionHandler)
        }
    }
    
    func removeValue(forKey key: String) throws {
        try KBSyncMethodReturningVoid { c in
            self.removeValue(forKey: key, completionHandler: c)
        }
    }
    
    func removeValues(forKeys keys: [String]) throws {
        try KBSyncMethodReturningVoid { c in
            self.removeValues(forKeys: keys, completionHandler: c)
        }
    }
    
    func removeValues(matching condition: KBGenericCondition) throws {
        try KBSyncMethodReturningVoid { c in
            self.removeValues(matching: condition, completionHandler: c)
        }
    }
    
    func removeAllValues() throws {
        try KBSyncMethodReturningVoid(execute: self.removeAllValues)
    }
    
    func triplesComponents(matching condition: KBTripleCondition?) throws -> [KBTriple] {
        return try KBSyncMethodReturningInitiable { c in
            self.triplesComponents(matching: condition, completionHandler: c)
        }
    }
    
    func verify(path: KBPath) throws -> Bool {
        try KBSyncMethodReturningInitiable { c in
            self.verify(path: path, completionHandler: c)
        }
    }
    
    func setWeight(forLinkWithLabel predicate: String, between subjectIdentifier: String, and objectIdentifier: String, toValue newValue: Int) throws {
        try KBSyncMethodReturningVoid { c in
            self.setWeight(forLinkWithLabel: predicate,
                           between: subjectIdentifier,
                           and: objectIdentifier,
                           toValue: newValue,
                           completionHandler: c)
        }
    }
    
    func increaseWeight(forLinkWithLabel predicate: String, between subjectIdentifier: String, and objectIdentifier: String) throws -> Int {
        try KBSyncMethodReturningInitiable { c in
            self.increaseWeight(forLinkWithLabel: predicate,
                                between: subjectIdentifier,
                                and: objectIdentifier,
                                completionHandler: c)
        }
    }
    
    func decreaseWeight(forLinkWithLabel predicate: Label,
                        between subjectIdentifier: Label,
                        and objectIdentifier: Label) throws -> Int {
        try KBSyncMethodReturningInitiable { c in
            self.decreaseWeight(forLinkWithLabel: predicate,
                                between: subjectIdentifier,
                                and: objectIdentifier,
                                completionHandler: c)
        }
    }
    
    func dropLink(withLabel predicate: String,
                  between subjectIdentifier: String,
                  and objectIdentifier: String) throws {
        try KBSyncMethodReturningVoid { c in
            self.dropLink(withLabel: predicate,
                          between: subjectIdentifier,
                          and: objectIdentifier,
                          completionHandler: c)
        }
    }
    
    func dropLinks(withLabel predicate: String?,
                   from subjectIdentifier: String) throws {
        try KBSyncMethodReturningVoid { c in
            self.dropLinks(withLabel: predicate,
                           from: subjectIdentifier,
                           completionHandler: c)
        }
    }
    
    func dropLinks(between subjectIdentifier: String,
                   and objectIdentifier: String) throws {
        try KBSyncMethodReturningVoid { c in
            self.dropLinks(between: subjectIdentifier,
                           and: objectIdentifier,
                           completionHandler: c)
        }
    }
    
    func disableSyncAndDeleteCloudData() throws {
        try KBSyncMethodReturningVoid { c in
            self.disableSyncAndDeleteCloudData(completionHandler: c)
        }
    }
}

/**
 Protocol that every backend needs to implement
 */
protocol KBBackingStore: KBBackingStoreProtocol {
    var name: String { get }
    func writeBatch() -> KBKVStoreWriteBatch
}

/**
 BackingStore using a SQL persistent storage handler.
 */
protocol KBPersistentBackingStore: KBBackingStore {
    var sqlHandler: KBSQLHandler { get }
}


