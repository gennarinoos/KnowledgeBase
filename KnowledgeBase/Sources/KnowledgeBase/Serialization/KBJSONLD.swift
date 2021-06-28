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

// MARK: - KBJSONLDGraph
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

// MARK: - CKKnowledgeStore + CKJSONLD

@available(iOS 15.0, *)
extension KBKnowledgeStore {
    
    @objc open func subgraph(withEntities identifiers: [Label]) -> KBJSONLDGraph {
        return KBJSONLDGraph(withEntities: identifiers.map {
            self.entity(withIdentifier: $0)
        })
    }
    
    internal func evaluateJSONLDEntry(forEntity entity: KBEntity,
                                      key: Any,
                                      value: Any) async throws {
        guard let _key = key as? String else {
            log.error("key=%{private}@ is not a string. class = %@", key as! String, String(describing: type(of: key)))
            throw KBError.unexpectedData(key)
        }
        
        if _key == "@context" || _key == "@id" {
            return
        }
        
        if let stringValue = value as? String {
            try await entity.link(to: self.entity(withIdentifier: stringValue),
                                  withPredicate: _key)
        } else if let stringArrayValue = value as? [String] {
            try await withThrowingTaskGroup(of: Void.self, body: { group in
                for stringValue in stringArrayValue {
                    group.async {
                        let otherEntity = self.entity(withIdentifier: stringValue)
                        try await entity.link(to: otherEntity, withPredicate: _key)
                    }
                }
            })
            return
        } else if let jsonObject = value as? KBJSONObject {
            let targetEntity = self.entity(withIdentifier: (jsonObject["@id"] ?? "_:\(UUID().uuidString)") as! String)
            
            try await withThrowingTaskGroup(of: Void.self, body: { group in
                for (k, v) in jsonObject {
                    group.async {
                        try await self.evaluateJSONLDEntry(forEntity: targetEntity, key: k, value: v)
                        }
                    }
                }
            })
            
            try await entity.link(to: targetEntity,
                        withPredicate: _key)
        } else if let jsonObjects = value as? [KBJSONObject] {
            try await withThrowingTaskGroup(of: Void.self, body: { group in
                for jsonObject in jsonObjects {
                    group.async {
                        try await self.evaluateJSONLDEntry(forEntity: entity, key: key, value: jsonObject)
                        }
                    }
                }
            })
        } else {
            throw KBError.notSupported
        }
    }
    
    fileprivate func `import`(entity: KBEntity,
                              fromJsonld jsonObject: Any) async throws {
        if let dictionary = jsonObject as? KBJSONObject {
            try await withThrowingTaskGroup(of: Void.self, body: { group in
                for (k, v) in dictionary {
                    group.async {
                        try await self.evaluateJSONLDEntry(forEntity: targetEntity, key: k, value: v)
                        }
                    }
                }
            })
        } else {
            throws JSONLDParseError.unexpectedFormat
        }
    }
    
    internal func importJSONLD(data: Data) async throws {
        let evaluate = {
            (object: KBJSONObject) async throws -> Void in
            let entity = self.entity(withIdentifier: (object["@id"] ?? "_:\(UUID().uuidString)") as! String)
            try await self.import(entity: entity, fromJsonld: object)
        }
        
        let object = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
        
        if let array = object as? [KBJSONObject] {
            try await withThrowingTaskGroup(of: Void.self, body: { group in
                for obj in array {
                    group.async {
                        try await evaluate(obj)
                    }
                }
            })
        } else if let obj = object as? KBJSONObject {
            try await evaluate(obj)
        }
    }
    
    //MARK: importContentsOfJSONLD(atPath:completionHandler:)
    
    @objc public func importContentsOfJSONLD(atPath path: String) async throws {
        
        if FileManager.default.fileExists(atPath: path) {
            do {
                let data = try Data(
                    contentsOf: URL(fileURLWithPath: path),
                    options: Data.ReadingOptions.alwaysMapped
                )
            } catch {
                log.error("error reading JSONLD file. %@", error.localizedDescription)
                throws error
            }
            
            try await withThrowingTaskGroup(of: Void.self, body: { group in
                for obj in array {
                    group.async {
                        try await self.importJSONLD(data: data)
                    }
                }
            })
        } else {
            log.error("no such JSONLD file at path %@", path)
            throw JSONLDParseError.resourceNotAvailable
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

