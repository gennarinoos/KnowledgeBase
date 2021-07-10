//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/8/21.
//

import Foundation
import CRDFStorage

class KBSPARQLEndpoint {
    internal let knowledgeStore: KBKnowledgeStore
    
    public init(with knowledgeStore: KBKnowledgeStore) {
        self.knowledgeStore = knowledgeStore
    }
    
    public func execute(query: String) async throws -> [Any] {
        guard let world = librdf_new_world() else {
            throw KBError.fatalError("Failed to initialize librdf_world")
        }
        
        librdf_world_open(world);
        
        return []
    }
    
    public func importTriples(fromFile path: String) {
        
    }
    
}
