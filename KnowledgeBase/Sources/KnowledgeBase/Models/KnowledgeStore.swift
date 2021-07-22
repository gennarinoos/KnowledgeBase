//
//  KnowledgeStore.swift
//
//
//  Created by Gennaro Frazzingaro on 7/16/21.
//

import Foundation


// MARK: - KBKnowledgeStoreDelegate

@objc(KBKnowledgeStoreDelegate)
public protocol KBKnowledgeStoreDelegate {
    func linkedDataDidChange()
}


@objc(KBKnowledgeStore)
open class KBKnowledgeStore : KBSyncKVStore {
    internal let sparqlQueue: DispatchQueue
    @objc open var delegate: KBKnowledgeStoreDelegate?
    
    public static let inMemoryGraph = KBKVStore.inMemoryStore() as! KBKnowledgeStore
    
    override init(_ location: Location) {
        self.sparqlQueue = DispatchQueue(label: "SPARQL",
                                         qos: .userInteractive)
        super.init(location)
    }
}



// MARK: - KnowledgeStore Read API

public extension KBKnowledgeStore {
    
    //MARK: entity(withIdentifier:)
    
    /**
     Construct a KBEntity object
     
     - parameter identifier: the unique identifier of the entity
     - returns: A KBEntity object
     
     */
    @objc func entity(withIdentifier identifier: Label) -> KBEntity {
        return KBEntity(identifier: identifier, knowledgeStore: self)
    }
}

