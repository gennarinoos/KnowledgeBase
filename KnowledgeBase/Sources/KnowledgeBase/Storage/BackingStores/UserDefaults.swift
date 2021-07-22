//
//  UserDefaults.swift
//
//
//  Created by Gennaro Frazzingaro on 6/22/21.
//

import Foundation


internal func KBAsyncMethodReturningVoid
(_ c: @escaping (Swift.Result<Void, Error>) -> (), f: @escaping () -> ()) {
    return c(.success(f()))
}

internal func KBAsyncMethodReturningInitiable<T: Initiable>(_ c: @escaping (Swift.Result<T, Error>) -> (), f: @escaping () -> T) {
    return c(.success(f()))
}


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
    
    func writeBatch() -> KBKVStoreWriteBatch {
        return KBUserDefaultsWriteBatch(backingStore: self)
    }

    //MARK: SELECT

    func keys(completionHandler: @escaping (Swift.Result<[String], Error>) -> ()) {
        KBAsyncMethodReturningInitiable(completionHandler) {
            return ((self.kv.dictionaryRepresentation() as NSDictionary).allKeys as! [String])
        }
    }
    
    func keys(matching condition: KBGenericCondition, completionHandler: @escaping (Swift.Result<[String], Error>) -> ()) {
        KBAsyncMethodReturningInitiable(completionHandler) {
            let filteredKeys = ((self.kv.dictionaryRepresentation() as NSDictionary).allKeys.filter {
                k -> Bool in
                return condition.evaluate(on: k)
            })
            return filteredKeys as! [String]
        }
    }
    
    internal func __value(forKey key: String) -> Any? {
        return self.kv.object(forKey: key)
    }
    
    func _value(forKey key: String, completionHandler: @escaping (Swift.Result<Any?, Error>) -> ()) {
        KBAsyncMethodReturningInitiable(completionHandler) {
            return self.__value(forKey: key)
        }
    }

    func values(completionHandler: @escaping (Swift.Result<[Any], Error>) -> ()) {
        KBAsyncMethodReturningInitiable(completionHandler) {
            return (self.kv.dictionaryRepresentation() as NSDictionary).allValues
        }
    }
    
    func values(forKeys keys: [String], completionHandler: @escaping (Swift.Result<[Any?], Error>) -> ()) {
        KBAsyncMethodReturningInitiable(completionHandler) {
            return keys.map { key in self.__value(forKey: key) }
        }
    }
    
    func values(forKeysMatching condition: KBGenericCondition, completionHandler: @escaping (Swift.Result<[Any?], Error>) -> ()) {
        self.keys() { result in
            switch result {
            case .success(let allKeys):
                let filteredKeys = allKeys.filter { condition.evaluate(on: $0) }
                let values = filteredKeys.map { key in self.__value(forKey: key) }
                completionHandler(.success(values))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    func dictionaryRepresentation(completionHandler: @escaping (Swift.Result<KBJSONObject, Error>) -> ()) {
        KBAsyncMethodReturningInitiable(completionHandler) {
            return self.kv.dictionaryRepresentation()
        }
    }
    
    func dictionaryRepresentation(forKeysMatching condition: KBGenericCondition,
                                  completionHandler: @escaping (Swift.Result<KBJSONObject, Error>) -> ()) {
        self.keys() { result in
            switch result {
            case .success(let allKeys):
                let dictionary = allKeys.reduce([:], {
                    (dict, k) in
                    if condition.evaluate(on: k) {
                        var newDict = dict
                        newDict[k] = self.__value(forKey: k)!
                        return newDict
                    }
                    return dict
                })
                completionHandler(.success(dictionary as! KBJSONObject))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    func triplesComponents(matching condition: KBTripleCondition?,
                           completionHandler: @escaping (Swift.Result<[KBTriple], Error>) -> ()) {
        log.fault(".UserDefaults store is not meant to store triples")
        completionHandler(.failure(KBError.notSupported))
    }
    
    func _setValue(_ value: Any?, forKey key: String, completionHandler: @escaping KBActionCompletion) {
        KBAsyncMethodReturningVoid(completionHandler) {
            self.kv.set(value, forKey: key)
        }
    }
        
    func removeValue(forKey key: String, completionHandler: @escaping KBActionCompletion) {
        KBAsyncMethodReturningVoid(completionHandler) {
            self.kv.removeObject(forKey: key)
            self.synchronize()
        }
    }
    
    func removeValues(forKeys keys: [String], completionHandler: @escaping KBActionCompletion) {
        KBAsyncMethodReturningVoid(completionHandler) {
            for key in keys {
                self.kv.removeObject(forKey: key)
            }
            self.synchronize()
        }
    }
    
    func removeValues(matching condition: KBGenericCondition, completionHandler: @escaping KBActionCompletion) {
        self.keys() { result in
            switch result {
            case .success(let allKeys):
                for key in allKeys {
                    if condition.evaluate(on: key) {
                        self.kv.removeObject(forKey: key)
                    }
                }
                self.synchronize()
                completionHandler(.success(()))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    func removeAllValues(completionHandler: @escaping KBActionCompletion) {
        self.keys() { result in
            switch result {
            case .success(let allKeys):
                for key in allKeys {
                    self.kv.removeObject(forKey: key)
                }
                self.synchronize()
                completionHandler(.success(()))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    // GRAPH LINKS
    func verify(path: KBPath, completionHandler: @escaping (Swift.Result<Bool, Error>) -> ()) {
        log.fault(".UserDefaults store is not meant to store graphs")
        completionHandler(.failure(KBError.notSupported))
    }
    
    func setWeight(forLinkWithLabel predicate: String,
                   between subjectIdentifier: String,
                   and objectIdentifier: String,
                   toValue newValue: Int,
                   completionHandler: @escaping KBActionCompletion) {
        log.fault(".UserDefaults store is not meant to store graphs")
        completionHandler(.failure(KBError.notSupported))
    }
    
    func increaseWeight(forLinkWithLabel predicate: String,
                        between subjectIdentifier: String,
                        and objectIdentifier: String,
                        completionHandler: @escaping (Swift.Result<Int, Error>) -> ()) {
        log.fault(".UserDefaults store is not meant to store graphs")
        completionHandler(.failure(KBError.notSupported))
    }
    
    func decreaseWeight(forLinkWithLabel predicate: Label,
                        between subjectIdentifier: Label,
                        and objectIdentifier: Label,
                        completionHandler: @escaping (Swift.Result<Int, Error>) -> ()) {
        log.fault(".UserDefaults store is not meant to store graphs")
        completionHandler(.failure(KBError.notSupported))
    }
    
    func dropLink(withLabel predicate: String,
                  between subjectIdentifier: String,
                  and objectIdentifier: String,
                  completionHandler: @escaping KBActionCompletion) {
        log.fault(".UserDefaults store is not meant to store graphs")
        completionHandler(.failure(KBError.notSupported))
    }
    
    func dropLinks(withLabel predicate: String?,
                   from subjectIdentifier: String,
                   completionHandler: @escaping KBActionCompletion) {
        log.fault(".UserDefaults store is not meant to store graphs")
        completionHandler(.failure(KBError.notSupported))
    }
    
    func dropLinks(between subjectIdentifier: String,
                   and objectIdentifier: String,
                   completionHandler: @escaping KBActionCompletion) {
        log.fault(".UserDefaults store is not meant to store graphs")
        completionHandler(.failure(KBError.notSupported))
    }
    
    // CLOUD SYNC
    func disableSyncAndDeleteCloudData(completionHandler: @escaping KBActionCompletion) {
        log.fault(".UserDefaults store does not support cloud syncing")
        completionHandler(.failure(KBError.notSupported))
    }
    
}

