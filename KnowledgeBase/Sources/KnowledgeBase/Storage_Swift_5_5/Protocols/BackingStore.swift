//
//  BackingStore.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/15/21.
//

protocol KBAsynchronousBackingStore {
    
    // MARK: KVStore
    func keys(completionHandler: @escaping (Swift.Result<[String], Error>) -> ())
    func keys(matching: KBGenericCondition, completionHandler: @escaping (Swift.Result<[String], Error>) -> ())
    func value(for key: String, completionHandler: @escaping (Swift.Result<Any?, Error>) -> ())
    func values(completionHandler: @escaping (Swift.Result<[Any], Error>) -> ())
    func values(for keys: [String], completionHandler: @escaping (Swift.Result<[Any?], Error>) -> ())
    func values(forKeysMatching: KBGenericCondition, completionHandler: @escaping (Swift.Result<[Any?], Error>) -> ())
    func dictionaryRepresentation(completionHandler: @escaping (Swift.Result<KBJSONObject, Error>) -> ())
    func dictionaryRepresentation(forKeysMatching: KBGenericCondition,
                                  completionHandler: @escaping (Swift.Result<KBJSONObject, Error>) -> ())
    func set(value: Any?, for key: String, completionHandler: @escaping KBActionCompletion)
    func removeValue(for key: String, completionHandler: @escaping KBActionCompletion)
    func removeValues(for keys: [String], completionHandler: @escaping KBActionCompletion)
    func removeValues(matching condition: KBGenericCondition, completionHandler: @escaping KBActionCompletion)
    func removeAll(completionHandler: @escaping KBActionCompletion)
    
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

protocol KBBackingStoreProtocol : KBAsynchronousBackingStore {
    
    // MARK: KVStore
    func keys() async throws -> [String]
    func keys(matching condition: KBGenericCondition) async throws -> [String]
    func value(for key: String) async throws -> Any?
    func values() async throws -> [Any]
    func values(for keys: [String]) async throws -> [Any?]
    func values(forKeysMatching condition: KBGenericCondition) async throws -> [Any?]
    func dictionaryRepresentation() async throws -> KBJSONObject
    func dictionaryRepresentation(forKeysMatching condition: KBGenericCondition) async throws -> KBJSONObject
    func set(value: Any?, for key: String) async throws
    func removeValue(for key: String) async throws
    func removeValues(for keys: [String]) async throws
    func removeValues(matching condition: KBGenericCondition) async throws
    func removeAll() async throws
    
    // MARK: KnowledgeStore
    func triplesComponents(matching condition: KBTripleCondition?) async throws -> [KBTriple]
    func verify(path: KBPath) async throws -> Bool
    func setWeight(forLinkWithLabel: Label,
                   between: Label,
                   and: Label,
                   toValue: Int) async throws
    func increaseWeight(forLinkWithLabel: String,
                        between: Label,
                        and: Label) async throws -> Int
    func decreaseWeight(forLinkWithLabel: Label,
                        between: Label,
                        and: Label) async throws -> Int
    func dropLink(withLabel: Label,
                  between: Label,
                  and: Label) async throws
    func dropLinks(withLabel: Label?,
                   from: Label) async throws
    func dropLinks(between: Label,
                   and: Label) async throws
    
    // MARK: Cloud sync
    func disableSyncAndDeleteCloudData() async throws
}


internal func KBModernAsyncMethodReturningVoid
(_ f: @escaping (@escaping (Swift.Result<Void, Error>) -> ()) -> ()) async throws {
    return try await withUnsafeThrowingContinuation {
        continuation in
        f {
            result in
            switch result {
            case .failure(let error):
                continuation.resume(throwing: error)
            case .success():
                continuation.resume()
            }
        }
    }
}

//internal func KBModernAsyncMethodReturningOptional
//<T>(_ f: @escaping (@escaping (Swift.Result<T?, Error>) -> ()) -> ()) async throws -> T? {
//    return try await withUnsafeThrowingContinuation {
//        continuation in
//        f {
//            result in
//            switch result {
//            case .failure(let error):
//                continuation.resume(throwing: error)
//            case .success(let result):
//                continuation.resume(with: .success(result))
//            }
//        }
//    }
//}

internal func KBModernAsyncMethodReturningInitiable
<T: Initiable>(_ f: @escaping (@escaping (Swift.Result<T, Error>) -> ()) -> ()) async throws -> T {
    return try await withUnsafeThrowingContinuation {
        continuation in
        f {
            result in
            switch result {
            case .failure(let error):
                continuation.resume(throwing: error)
            case .success(let result):
                continuation.resume(with: .success(result))
            }
        }
    }
}

extension KBBackingStoreProtocol {
    func keys() async throws -> [String] {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.keys(completionHandler: c)
        }
    }
    
    func keys(matching condition: KBGenericCondition) async throws -> [String] {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.keys(matching: condition, completionHandler: c)
        }
    }
    
    func value(for key: String) async throws -> Any? {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.value(for: key, completionHandler: c)
        }
    }
    
    func values() async throws -> [Any] {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.values(completionHandler: c)
        }
    }
    
    func values(for keys: [String]) async throws -> [Any?] {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.values(for: keys, completionHandler: c)
        }
    }
    
    func values(forKeysMatching condition: KBGenericCondition) async throws -> [Any?] {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.values(forKeysMatching: condition, completionHandler: c)
        }
    }
    
    func dictionaryRepresentation() async throws -> KBJSONObject {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.dictionaryRepresentation(completionHandler: c)
        }
    }
    
    func dictionaryRepresentation(forKeysMatching condition: KBGenericCondition) async throws -> KBJSONObject {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.dictionaryRepresentation(forKeysMatching: condition, completionHandler: c)
        }
    }
    
    func triplesComponents(matching condition: KBTripleCondition?) async throws -> [KBTriple] {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.triplesComponents(matching: condition, completionHandler: c)
        }
    }
    
    func set(value: Any?, for key: String) async throws {
        try await KBModernAsyncMethodReturningVoid { c in
            self.set(value: value, for: key, completionHandler: c)
        }
    }

    func removeValue(for key: String) async throws {
        try await KBModernAsyncMethodReturningVoid { c in
            self.removeValue(for: key, completionHandler: c)
        }
    }
    
    func removeValues(for keys: [String]) async throws {
        try await KBModernAsyncMethodReturningVoid { c in
            self.removeValues(for: keys, completionHandler: c)
        }
    }
    func removeValues(matching condition: KBGenericCondition) async throws {
        try await KBModernAsyncMethodReturningVoid { c in
            self.removeValues(matching: condition, completionHandler: c)
        }
    }
    
    func removeAll() async throws {
        try await KBModernAsyncMethodReturningVoid { c in
            self.removeAll(completionHandler: c)
        }
    }
    
    func verify(path: KBPath) async throws -> Bool {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.verify(path: path, completionHandler: c)
        }
    }
    
    func setWeight(forLinkWithLabel predicate: Label,
                   between subjectIdentifier: Label,
                   and objectIdentifier: Label,
                   toValue newValue: Int) async throws {
        try await KBModernAsyncMethodReturningVoid { c in
            self.setWeight(forLinkWithLabel: predicate,
                           between: subjectIdentifier,
                           and: objectIdentifier,
                           toValue: newValue,
                           completionHandler: c)
        }
    }
    
    func increaseWeight(forLinkWithLabel predicate: String,
                        between subjectIdentifier: Label,
                        and objectIdentifier: Label) async throws -> Int {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.increaseWeight(forLinkWithLabel: predicate,
                                between: subjectIdentifier,
                                and: objectIdentifier,
                                completionHandler: c)
        }
    }
    
    func decreaseWeight(forLinkWithLabel predicate: Label,
                        between subjectIdentifier: Label,
                        and objectIdentifier: Label) async throws -> Int {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.decreaseWeight(forLinkWithLabel: predicate,
                                between: subjectIdentifier,
                                and: objectIdentifier,
                                completionHandler: c)
        }
    }
    
    func dropLink(withLabel predicate: Label,
                  between subjectIdentifier: Label,
                  and objectIdentifier: Label) async throws {
        try await KBModernAsyncMethodReturningVoid { c in
            self.dropLink(withLabel: predicate,
                          between: subjectIdentifier,
                          and: objectIdentifier,
                          completionHandler: c)
        }
    }
    
    func dropLinks(withLabel predicate: Label?,
                   from subjectIdentifier: Label) async throws {
        try await KBModernAsyncMethodReturningVoid { c in
            self.dropLinks(withLabel: predicate, from: subjectIdentifier, completionHandler: c)
        }
    }
    
    func dropLinks(between subjectIdentifier: Label,
                   and objectIdentifier: Label) async throws {
        try await KBModernAsyncMethodReturningVoid { c in
            self.dropLinks(between: subjectIdentifier, and: objectIdentifier, completionHandler: c)
        }
    }
    
    func disableSyncAndDeleteCloudData() async throws {
        try await KBModernAsyncMethodReturningVoid { c in
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