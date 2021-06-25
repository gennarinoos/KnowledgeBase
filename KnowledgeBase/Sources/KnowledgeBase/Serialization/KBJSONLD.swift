//
//  KBJSONLD.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/22/21.
//

import Foundation

public typealias KBJSONObject = [String: Any]

enum JSONLDParseError: Error {
    case unexpectedFormat, resourceNotAvailable
}

// - MARK KBJSONLDGraph
@objc(KBJSONLDGraph)
open class KBJSONLDGraph : NSObject {

    fileprivate let _entities: [KBEntity]
    private let queue: DispatchQueue

    @objc public init(withEntities entities: [KBEntity]?) {
        self._entities = entities ?? []
        self.queue = DispatchQueue(label: "\(KnowledgeBaseBundleIdentifier).KBJSONLDGraph", attributes: .concurrent)
    }

    @objc open var entities: [String] {
        return self._entities.map { $0.identifier }
    }

    @objc open func linkedData() async throws -> [KBJSONObject] {
        var linkedDataDictionary = [KBJSONObject]()
        let entities = Array(Set(self._entities))
        
        self.queue.async {
            for entity in entities {
                do {
                    linkedDataDictionary.append(try KBJSONLDGraph.serialize(entity))
                } catch {
                    log.error("serialization of %{private}@ failed. %@", entity, error.localizedDescription)
                    throw error
                }
            }
            reutrn linkedDataDictionary
        }
    }

    private static func serialize(_ entity: KBEntity) throws -> KBJSONObject {
        var object = KBJSONObject()
        //            object["@context"] = "http://schema.org/"
        object["@id"] = entity.identifier

        for (link, linkedEntity) in try entity.linkedEntities() {
            object.append(link, value: linkedEntity.identifier)
        }
        
        return object
    }
}

// - MARK CKKnowledgeStore + CKJSONLD

extension CKKnowledgeStore {
    
    @objc open func subgraph(withEntities identifiers: [Label]) -> KBJSONLDGraph {
        return KBJSONLDGraph(withEntities: identifiers.map {
            self.entity(withIdentifier: $0)
        })
    }
    
    internal func evaluateJSONLDEntry(forEntity entity: KBEntity,
                                      key: Any,
                                      value: Any,
                                      completionHandler: @escaping CKActionCompletion) {
        guard let _key = key as? String else {
            log.error("key=%{private}@ is not a string. class = %@", key as! String, String(describing: type(of: key)))
            completionHandler(KBError.unexpectedData(key))
            return
        }
        
        if _key == "@context" || _key == "@id" {
            completionHandler(nil)
            return
        }
        
        if let stringValue = value as? String {
            entity.link(to: self.entity(withIdentifier: stringValue),
                        withPredicate: _key,
                        completionHandler: completionHandler)
        } else if let stringArrayValue = value as? [String] {
            let dispatch = CKTimedDispatch(timeout: .now() + .seconds(stringArrayValue.count))
            for stringValue in stringArrayValue {
                autoreleasepool {
                    dispatch.group.enter()
                    entity.link(to: self.entity(withIdentifier: stringValue), withPredicate: _key) {
                        if let _ = $0 { dispatch.interrupt($0!) }
                        else { dispatch.group.leave() }
                    }
                }
            }
            do {
                try dispatch.wait()
                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        } else if let jsonObject = value as? KBJSONObject {
            let dispatch = CKTimedDispatch(timeout: .distantFuture)
            
            let targetEntity = self.entity(withIdentifier: (jsonObject["@id"] ?? "_:\(UUID().uuidString)") as! String)
            
            for (k, v) in jsonObject {
                autoreleasepool {
                    dispatch.group.enter()
                    self.evaluateJSONLDEntry(forEntity: targetEntity, key: k, value: v) {
                        (error: Error?) in
                        if let _ = error {
                            dispatch.interrupt(error!)
                        } else {
                            dispatch.group.leave()
                        }
                    }
                }
            }
            
            do {
                try dispatch.wait()
            } catch {
                completionHandler(error)
                return
            }
            
            entity.link(to: targetEntity,
                        withPredicate: _key,
                        completionHandler: completionHandler)
        } else if let jsonObjects = value as? [KBJSONObject] {
            let dispatch = CKTimedDispatch(timeout: .distantFuture)
            
            for jsonObject in jsonObjects {
                dispatch.group.enter()
                self.evaluateJSONLDEntry(forEntity: entity, key: key, value: jsonObject) {
                    (error: Error?) in
                    if let _ = error {
                        dispatch.interrupt(error!)
                    } else {
                        dispatch.group.leave()
                    }
                }
            }
            
            do {
                try dispatch.wait()
                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        } else {
            completionHandler(KBError.notSupported)
        }
    }
    
    fileprivate func `import`(entity: KBEntity,
                              fromJsonld jsonObject: Any,
                              completionHandler: @escaping CKActionCompletion) {
        if let dictionary = jsonObject as? KBJSONObject {
            let dispatch = CKTimedDispatch(timeout: .distantFuture)
            
            for (k, v) in dictionary {
                autoreleasepool {
                    dispatch.group.enter()
                    self.evaluateJSONLDEntry(forEntity: entity, key: k, value: v) {
                        (error: Error?) in
                        if let _ = error {
                            dispatch.interrupt(error!)
                        } else {
                            dispatch.group.leave()
                        }
                    }
                }
            }
            
            do {
                try dispatch.wait()
                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        } else {
            completionHandler(JSONLDParseError.unexpectedFormat)
        }
    }
    
    internal func importJSONLD(data: Data, completionHandler: @escaping CKActionCompletion) {
        let evaluate = {
            (object: KBJSONObject, completionHandler: @escaping CKActionCompletion) -> Void in
            let entity = self.entity(withIdentifier: (object["@id"] ?? "_:\(UUID().uuidString)") as! String)
            self.import(entity: entity, fromJsonld: object, completionHandler: completionHandler)
        }
        
        let object: Any
        
        do {
            object = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
        } catch {
            completionHandler(error)
            return
        }
        
        let dispatch = CKTimedDispatch(timeout: .distantFuture)
        
        if let array = object as? [KBJSONObject] {
            for obj in array {
                dispatch.group.enter()
                evaluate(obj) {
                    (error: Error?) in
                    if let _ = error {
                        dispatch.interrupt(error!)
                    } else {
                        dispatch.group.leave()
                    }
                }
            }
        } else if let obj = object as? KBJSONObject {
            evaluate(obj) {
                (error: Error?) in
                if let _ = error {
                    dispatch.interrupt(error!)
                } else {
                    dispatch.group.leave()
                }
            }
        }
        
        do {
            try dispatch.wait()
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }
    
    //MARK: importContentsOfJSONLD(atPath:completionHandler:)
    
    @objc open func importContentsOfJSONLD(atPath path: String,
                                           completionHandler: CKActionCompletion? = nil) {
        
        if FileManager.default.fileExists(atPath: path) {
            do {
                let data = try Data(
                    contentsOf: URL(fileURLWithPath: path),
                    options: Data.ReadingOptions.alwaysMapped
                )
                DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
                    self.importJSONLD(data: data, completionHandler: completionHandler ?? {
                        (error: Error?) in
                        log.error("error importing JSONLD data")
                        }
                    )
                }
            } catch {
                log.error("error reading JSONLD file. %@", error.localizedDescription)
                completionHandler?(error)
            }
        } else {
            log.error("no such JSONLD file at path %@", path)
            completionHandler?(JSONLDParseError.resourceNotAvailable)
        }
    }
    
}

extension Dictionary {
    
    mutating func append(_ key: Key, value: Value) {
        guard key is String else { return }
        
        if let previousValue = self[key] , self[key] != nil {
            if var array = previousValue as? Array<Any> {
                array.append(value)
            } else {
                var list = [Any]()
                list.append(previousValue)
                list.append(value)
                self[key] = list as? Value
            }
        } else {
            self[key] = value
        }
    }
}

