//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/8/21.
//

import Foundation
import RDFStorage

class KBSPARQLEndpoint {
    internal let rdfStore: BaseRDFStore
    
    public init(with knowledgeStore: KBKnowledgeStore) {
        self.rdfStore = BaseRDFStore(tripleStore: knowledgeStore)
    }
    
    public func execute(query: String) async throws -> [Any] {
        try self.rdfStore.execute(SPARQLQuery: query)
    }
    
    public func importTurtle(fromFileAt path: String) async throws {
        try await self.rdfStore.importTriples(fromFileAtPath: path)
    }
    
}
