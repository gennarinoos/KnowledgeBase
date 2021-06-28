//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/22/21.
//

import Foundation


let KnowledgeBaseXPCServiceBundleIdentifier = "com.gf.knowledgebase.storage.service"

internal func NSNullToNil(_ v: Any) -> Any? {
    if v is NSNull {
        return nil
    }
    return v
}

internal func nilToNSNull(_ v: Any?) -> Any {
    if v == nil {
        return NSNull()
    }
    return v!
}

#if os(macOS)
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
    
    func daemon(errorHandler: @escaping (Error) -> ()) -> KBStorageXPCInterface? {
        return self.connection.remoteObjectProxyWithErrorHandler { (error) in
            log.fault("XPC connection error %s", error.localizedDescription)
            errorHandler(error)
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
    
    func keys(completionHandler: @escaping (Error?, [String]) -> ()) {
            self.daemon(errorHandler: KBErrorHandler(completionHandler))?
                .keys(inStoreWithIdentifier: self.name, completionHandler: completionHandler)
    }
    
    func keys(matching condition: KBGenericCondition, completionHandler: @escaping (Error?, [String]) -> ()) {
            self.daemon(errorHandler: KBErrorHandler(completionHandler))?
                .keys(matching: condition, inStoreWithIdentifier: self.name) {
                    (error, keys) in
                    let _ = self // Retain self in the block to keep XPC connection alive
                    completionHandler(error, keys)
            }
    }
    
    func value(forKey key: String,
               completionHandler: @escaping (Error?, Any?) -> ()) {
            self.daemon(errorHandler: KBErrorHandler(completionHandler))?
                .value(forKey: key, inStoreWithIdentifier: self.name) {
                    (error, value) in
                    let _ = self // Retain self in the block to keep XPC connection alive
                    completionHandler(error, value)
            }
    }
    
    func values(completionHandler: @escaping (Error?, [Any]) -> ()) {
            self.daemon(errorHandler: KBErrorHandler(completionHandler))?
                .values(inStoreWithIdentifier: self.name) {
                    (error, values) in
                    let _ = self // Retain self in the block to keep XPC connection alive
                    completionHandler(error, values)
            }
    }
    
    func values(forKeys keys: [String], completionHandler: @escaping (Error?, [Any?]) -> ()) {
            self.daemon(errorHandler: KBErrorHandler(completionHandler))?
                .values(forKeys: keys, inStoreWithIdentifier: self.name) {
                    (error: Error?, objcValues: [Any]) in
                    let _ = self // Retain self in the block to keep XPC connection alive
                    let values: [Any?] = objcValues.map(NSNullToNil)
                    completionHandler(error, values)
            }
    }
    
    func values(forKeysMatching condition: KBGenericCondition, completionHandler: @escaping (Error?, [Any]) -> ()) {
            self.daemon(errorHandler: KBErrorHandler(completionHandler))?
                .values(forKeysMatching: condition, inStoreWithIdentifier: self.name) {
                    (error, values) in
                    let _ = self // Retain self in the block to keep XPC connection alive
                    completionHandler(error, values)
            }
    }
    
    func dictionaryRepresentation(completionHandler: @escaping (Error?, KBJSONObject) -> ()) {
            self.daemon(errorHandler: KBErrorHandler(completionHandler))?
                .keysAndValues(inStoreWithIdentifier: self.name) {
                    (error, keysAndValues) in
                    let _ = self // Retain self in the block to keep XPC connection alive
                    completionHandler(error, keysAndValues)
            }
    }
    
    func dictionaryRepresentation(forKeysMatching condition: KBGenericCondition, completionHandler: @escaping (Error?, KBJSONObject) -> ()) {
            self.daemon(errorHandler: KBErrorHandler(completionHandler))?
                .keysAndValues(forKeysMatching: condition,
                               inStoreWithIdentifier: self.name) {
                                (error, keysAndValues) in
                                let _ = self // Retain self in the block to keep XPC connection alive
                                completionHandler(error, keysAndValues)
            }
    }
    
    func triplesComponents(matching condition: KBTripleCondition?,
                           completionHandler: @escaping (Error?, [KBTriple]) -> ()) {
            self.daemon(errorHandler: KBErrorHandler(completionHandler))?
                .triplesComponents(matching: condition,
                                   inStoreWithIdentifier: self.name) {
                                    (error, triples) in
                                    let _ = self // Retain self in the block to keep XPC connection alive
                                    completionHandler(error, triples)
            }
    }
    
    func verify(path: CKPath, completionHandler: @escaping (Error?, Bool) -> ()) {
        log.error("path search in .SQL store not yet supported.") // TODO: Support
        completionHandler(KBError.notSupported, false)
    }

    //MARK: INSERT
    
    func setValue(_ value: Any?,
                  forKey key: String,
                  completionHandler: @escaping CKActionCompletion) {
            self.daemon(errorHandler: completionHandler)?
                .save([key: value ?? NSNull()],
                      toStoreWithIdentifier: self.name) {
                        error in
                        let _ = self // Retain self in the block to keep XPC connection alive
                        completionHandler(error)
            }
    }

    func writeBatch() -> KBKnowledgeStoreWriteBatch {
        return KBSQLXPCWriteBatch(backingStore: self)
    }

    func setWeight(forLinkWithLabel predicate: String,
                   between subjectIdentifier: String,
                   and objectIdentifier: String,
                   toValue newValue: Int,
                   completionHandler: @escaping CKActionCompletion) {
            self.daemon(errorHandler: completionHandler)?
                .setWeight(forLinkWithLabel: predicate,
                           between: subjectIdentifier,
                           and: objectIdentifier,
                           toValue: newValue,
                           inStoreWithIdentifier: self.name) {
                            error in
                            let _ = self // Retain self in the block to keep XPC connection alive
                            completionHandler(error)
            }
    }
    
    func increaseWeight(forLinkWithLabel predicate: String,
                        between subjectIdentifier: String,
                        and objectIdentifier: String,
                        completionHandler: @escaping CKActionReturningIntegerCompletion) {
            self.daemon(errorHandler: KBErrorHandler(completionHandler))?
                .increaseWeight(forLinkWithLabel: predicate,
                                between: subjectIdentifier,
                                and: objectIdentifier,
                                inStoreWithIdentifier: self.name) {
                                    (error, result) in
                                    let _ = self // Retain self in the block to keep XPC connection alive
                                    completionHandler(error, result)
            }
    }
    
    func decreaseWeight(forLinkWithLabel predicate: Label,
                        between subjectIdentifier: Label,
                        and objectIdentifier: Label,
                        completionHandler: @escaping CKActionReturningIntegerCompletion) {
            self.daemon(errorHandler: KBErrorHandler(completionHandler))?
                .decreaseWeight(forLinkWithLabel: predicate,
                                between: subjectIdentifier,
                                and: objectIdentifier,
                                inStoreWithIdentifier: self.name) {
                                    (error, result) in
                                    let _ = self // Retain self in the block to keep XPC connection alive
                                    completionHandler(error, result)
            }
    }

    //MARK: DELETE
    
    func removeValue(forKey key: String, completionHandler: @escaping CKActionCompletion) {
            self.daemon(errorHandler: completionHandler)?
                .removeValue(forKey: key,
                             fromStoreWithIdentifier: self.name) {
                                error in
                                let _ = self // Retain self in the block to keep XPC connection alive
                                completionHandler(error)
            }
    }
    
    func removeValues(forKeys keys: [String], completionHandler: @escaping CKActionCompletion) {
            self.daemon(errorHandler: completionHandler)?
                .removeValues(forKeys: keys,
                              fromStoreWithIdentifier: self.name) {
                                error in
                                let _ = self // Retain self in the block to keep XPC connection alive
                                completionHandler(error)
            }
    }
    
    func removeValues(matching condition: KBGenericCondition, completionHandler: @escaping CKActionCompletion) {
            self.daemon(errorHandler: completionHandler)?
                .removeValues(matching: condition,
                              fromStoreWithIdentifier: self.name) {
                                error in
                                let _ = self // Retain self in the block to keep XPC connection alive
                                completionHandler(error)
            }
    }
    
    func removeAllValues(completionHandler: @escaping CKActionCompletion) {
            self.daemon(errorHandler: completionHandler)?
                .removeAllValues(fromStoreWithIdentifier: self.name) {
                    error in
                    let _ = self // Retain self in the block to keep XPC connection alive
                    completionHandler(error)
            }
    }
    
    func dropLink(withLabel predicate: String,
                  between subjectIdentifier: String,
                  and objectIdentifier: String,
                  completionHandler: @escaping CKActionCompletion) {
            self.daemon(errorHandler: completionHandler)?
                .dropLink(withLabel: predicate,
                          between: subjectIdentifier,
                          and: objectIdentifier,
                          inStoreWithIdentifier: self.name) {
                            error in
                            let _ = self // Retain self in the block to keep XPC connection alive
                            completionHandler(error)
            }
    }
    
    func dropLinks(withLabel predicate: String?,
                   from subjectIdentifier: String,
                   completionHandler: @escaping CKActionCompletion) {
            self.daemon(errorHandler: completionHandler)?
                .dropLinks(withLabel: predicate,
                           from: subjectIdentifier,
                           inStoreWithIdentifier: self.name) {
                            error in
                            let _ = self // Retain self in the block to keep XPC connection alive
                            completionHandler(error)
            }
    }
    
    func dropLinks(between subjectIdentifier: String,
                   and objectIdentifier: String) async throws {
            self.daemon(errorHandler: completionHandler)?
                .dropLinks(between: subjectIdentifier,
                           and: objectIdentifier,
                           inStoreWithIdentifier: self.name) {
                            error in
                            let _ = self // Retain self in the block to keep XPC connection alive
                            completionHandler(error)
            }
    }
    
    func disableSyncAndDeleteCloudData() async throws {
        throw KBError.notSupported
    }
}
#endif

