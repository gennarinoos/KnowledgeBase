//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/8/21.
//

import Foundation
import RDFStorage

@available(macOS 12.0, *)
class KBSPARQLEndpoint {
    internal let rdfStore: BaseRDFStore
    
    public init(with knowledgeStore: KBKnowledgeStore) {
        self.rdfStore = BaseRDFStore(tripleStore: knowledgeStore)
    }
    
    public func execute(query: String) async throws -> [Any] {
        try self.rdfStore.execute(SPARQLQuery: query)
    }
    
    public func importTriples(fromFile path: String) {
        self.rdfStore.importTriples(fromFileAtPath: path)
    }
    
}
