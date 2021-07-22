//
//  BackingStore.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/15/21.
//

#if HAS_ASYNC_AWAIT // No need for the synchronous version with Swift 5.5 or greater.
typealias KBBackingStoreProtocol = KBAsynchronousBackingStore
#endif

extension KBAsynchronousBackingStore {
    // KVS SELECT
    func keys() async throws -> [String]
    func keys(matching: KBGenericCondition) async throws -> [String]
    func value(forKey key: String) async throws -> Any?
    func values() async throws -> [Any]
    func values(forKeys keys: [String]) async throws -> [Any?]
    func values(forKeysMatching: KBGenericCondition) async throws -> [Any]
    func dictionaryRepresentation() async throws -> KBJSONObject
    func dictionaryRepresentation(forKeysMatching: KBGenericCondition) async throws -> KBJSONObject
    func triplesComponents(matching: KBTripleCondition?) async throws -> [KBTriple]
        
    // KVS INSERT
    func _setValue(_: Any?, forKey: String) async throws
        
    // KVS DELETE
    func removeValue(forKey: String) async throws
    func removeValues(forKeys: [String]) async throws
    func removeValues(matching: KBGenericCondition) async throws
    func removeAllValues() async throws
       
   // GRAPH LINKS
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
    
    // CLOUD SYNC
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

extension KBModernAsynchronousBackingStore {
    func keys() async throws -> [String] {
        return try await KBModernAsyncMethodReturningInitiable({ c in
            self.keys(completionHandler: c)
        })
    }
    
    func keys(matching condition: KBGenericCondition) async throws -> [String] {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.keys(matching: condition, completionHandler: c)
        }
    }
    
    func _value(forKey key: String) async throws -> Any? {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self._value(forKey: key, completionHandler: c)
        }
    }
    
    func values() async throws -> [Any] {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.values(completionHandler: c)
        }
    }
    
    func values(forKeys keys: [String]) async throws -> [Any?] {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.values(forKeys: keys, completionHandler: c)
        }
    }
    
    func values(forKeysMatching condition: KBGenericCondition) async throws -> [Any] {
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
    
    func _setValue(_ value: Any?, forKey key: String) async throws {
        try await KBModernAsyncMethodReturningVoid { c in
            self._setValue(value, forKey: key, completionHandler: c)
        }
    }
        
    // KVS DELETE
    func removeValue(forKey key: String) async throws {
        try await KBModernAsyncMethodReturningVoid { c in
            self.removeValue(forKey: key, completionHandler: c)
        }
    }
    
    func removeValues(forKeys keys: [String]) async throws {
        try await KBModernAsyncMethodReturningVoid { c in
            self.removeValues(forKeys: keys, completionHandler: c)
        }
    }
    func removeValues(matching condition: KBGenericCondition) async throws {
        try await KBModernAsyncMethodReturningVoid { c in
            self.removeValues(matching: condition, completionHandler: c)
        }
    }
    
    func removeAllValues() async throws {
        try await KBModernAsyncMethodReturningVoid { c in
            self.removeAllValues(completionHandler: c)
        }
    }
       
   // GRAPH LINKS
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
    
    // CLOUD SYNC
    func disableSyncAndDeleteCloudData() async throws {
        try await KBModernAsyncMethodReturningVoid { c in
            self.disableSyncAndDeleteCloudData(completionHandler: c)
        }
    }
}
