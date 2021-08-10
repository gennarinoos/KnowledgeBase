//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/27/21.
//

import Foundation

public var DatabaseExtension = "db"

protocol KBSQLBackingStoreProtocol : KBPersistentBackingStore {
}

extension KBSQLBackingStoreProtocol {
    
    internal func genericMethodReturningVoid(_ c: @escaping (Swift.Result<Void, Error>) -> (), f: @escaping () throws -> ()) {
        do {
            try f()
            return c(.success(()))
        } catch {
            return c(.failure(error))
        }
    }
    
    internal func genericMethodReturningInitiable
<T: Initiable>(_ c: @escaping (Swift.Result<T, Error>) -> (), f: @escaping () throws -> T) {
        do {
            return c(.success(try f()))
        } catch {
            return c(.failure(error))
        }
    }
    
    func keys(completionHandler: @escaping (Swift.Result<[String], Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            return try self.sqlHandler.keys()
        }
    }
    
    func keys(matching condition: KBGenericCondition, completionHandler: @escaping (Swift.Result<[String], Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            return try self.sqlHandler.keys(matching: condition)
        }
    }
    
    func value(for key: String, completionHandler: @escaping (Swift.Result<Any?, Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            let value = try self.sqlHandler.values(for: [key]).first
            if let v = value {
                return NSNullToNil(v)
            }
            return value
        }
    }
    
    func values(for keys: [String], completionHandler: @escaping (Swift.Result<[Any?], Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            return try self.sqlHandler.values(for: keys).map(NSNullToNil)
        }
    }
    
    func values(forKeysMatching condition: KBGenericCondition, completionHandler: @escaping (Swift.Result<[Any?], Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            return try self.sqlHandler.values(forKeysMatching: condition).map(NSNullToNil)
        }
    }
    
    func values(completionHandler: @escaping (Swift.Result<[Any], Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            return try self.sqlHandler.values()
        }
    }
    
    func dictionaryRepresentation(completionHandler: @escaping (Swift.Result<KBJSONObject, Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            return try self.sqlHandler.keysAndValues()
        }
    }
    
    func dictionaryRepresentation(forKeysMatching condition: KBGenericCondition,
                                  completionHandler: @escaping (Swift.Result<KBJSONObject, Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            return try self.sqlHandler.keysAndvalues(forKeysMatching: condition)
        }
    }
    
    func triplesComponents(matching condition: KBTripleCondition?,
                           completionHandler: @escaping (Swift.Result<[KBTriple], Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            try self.sqlHandler.tripleComponents(matching: condition)
        }
    }
    
    func verify(path: KBPath, completionHandler: @escaping (Swift.Result<Bool, Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            try self.sqlHandler.verify(path: path)
        }
    }

    //MARK: INSERT
    
    func set(value: Any?, for key: String, completionHandler: @escaping KBActionCompletion) {
        genericMethodReturningVoid(completionHandler) {
            self.writeBatch().set(value: value, for: key)
            (self.writeBatch() as! KBSQLWriteBatch).write(completionHandler: completionHandler)
        }
    }
    
    func setWeight(forLinkWithLabel predicate: String,
                   between subjectIdentifier: String,
                   and objectIdentifier: String,
                   toValue newValue: Int,
                   completionHandler: @escaping KBActionCompletion) {
        genericMethodReturningVoid(completionHandler) {
            try self.sqlHandler.setWeight(forLinkWithLabel: predicate,
                                          between: subjectIdentifier,
                                          and: objectIdentifier,
                                          toValue: newValue)
        }
    }
    
    func increaseWeight(forLinkWithLabel predicate: String,
                        between subjectIdentifier: String,
                        and objectIdentifier: String,
                        completionHandler: @escaping (Swift.Result<Int, Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            try self.sqlHandler.increaseWeight(forLinkWithLabel: predicate,
                                               between: subjectIdentifier,
                                               and: objectIdentifier)
        }
    }
    
    func decreaseWeight(forLinkWithLabel predicate: Label,
                        between subjectIdentifier: Label,
                        and objectIdentifier: Label,
                        completionHandler: @escaping (Swift.Result<Int, Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            try self.sqlHandler.decreaseWeight(forLinkWithLabel: predicate,
                                               between: subjectIdentifier,
                                               and: objectIdentifier)
        }
    }
    
    //MARK: DELETE
    
    func removeValue(for key: String, completionHandler: @escaping KBActionCompletion) {
        genericMethodReturningVoid(completionHandler) {
            try self.sqlHandler.removeValue(for: key)
        }
    }
    
    func removeValues(for keys: [String], completionHandler: @escaping KBActionCompletion) {
        genericMethodReturningVoid(completionHandler) {
            try self.sqlHandler.removeValues(for: keys)
        }
    }
    
    func removeValues(forKeysMatching condition: KBGenericCondition, completionHandler: @escaping (Swift.Result<[String], Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            let keys = try self.sqlHandler.keys(matching: condition)
            try self.sqlHandler.removeValues(for: keys)
            return keys
        }
    }
    
    func removeAll(completionHandler: @escaping (Swift.Result<[String], Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            let keys = try self.sqlHandler.keys()
            try self.sqlHandler.removeValues(for: keys)
            return keys
        }
    }
    
    func dropLink(withLabel predicate: String,
                  between subjectIdentifier: String,
                  and objectIdentifier: String,
                  completionHandler: @escaping KBActionCompletion) {
        genericMethodReturningVoid(completionHandler) {
            try self.sqlHandler.dropLink(withLabel: predicate,
                                                          between: subjectIdentifier,
                                                          and: objectIdentifier)
        }
    }
    
    func dropLinks(withLabel predicate: String?,
                   from subjectIdentifier: String,
                   completionHandler: @escaping KBActionCompletion) {
        genericMethodReturningVoid(completionHandler) {
            try self.sqlHandler.dropLinks(withLabel: predicate,
                                                   from: subjectIdentifier)
        }
    }
    
    func dropLinks(between subjectIdentifier: String,
                   and objectIdentifier: String,
                   completionHandler: @escaping KBActionCompletion) {
        genericMethodReturningVoid(completionHandler) {
            try self.sqlHandler.dropLinks(between: subjectIdentifier,
                                                           and: objectIdentifier)
        }
    }
    
    func disableSyncAndDeleteCloudData(completionHandler: @escaping KBActionCompletion) {
        completionHandler(.failure(KBError.notSupported))
    }
}


class KBSQLBackingStore : KBSQLBackingStoreProtocol {
    
    var name: String
    
    // SQL database on disk
    var sqlHandler: KBSQLHandler {
        get {
            return KBSQLHandler.init(name: self.name)!
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
            path = try FileManager.default.url(for: .libraryDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
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
    
    func writeBatch() -> KBKVStoreWriteBatch {
        return KBSQLWriteBatch(backingStore: self)
    }
}

