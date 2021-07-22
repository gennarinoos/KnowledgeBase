//
//  TripleStoreWriteAPIs.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/18/21.
//

import Foundation
import RDFStorage

extension KBKnowledgeStore {
    
    /**
     Remove the entity with a certain identifier.
     WARN: This will remove all the connections to this entity in the graph.
     
     - parameter identifier: the identifier
     */
    @objc open func removeEntity(_ identifier: Label) async throws {
        log.debug("[$? <%{private}@> $?]", identifier)
        
        let subjectMatches = KBTripleCondition(
            subject: identifier,
            predicate: nil,
            object: nil
        )
        let objectMatches = KBTripleCondition(
            subject: nil,
            predicate: nil,
            object: identifier
        )
        let condition = subjectMatches.or(objectMatches)
        
        try await self.backingStore.removeValues(matching: condition.rawCondition)
    }
    
    @objc open func importContentsOf(turtleFileAt path: String) async throws {
        return try await withUnsafeThrowingContinuation { continuation in
            let solver = KBSPARQLEndpoint(with: self)
            solver.importTurtle(fromFileAt: path) { result in
                switch result {
                case .success(): continuation.resume()
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /**
     Executes the SPARQL SELECT query and returns all the bounded values in the projection.
     
     - parameter query: the SPARQL SELECT query to execute
     */
    @objc open func execute(SPARQLQuery query: String) throws -> [Any] {
        let solver = KBSPARQLEndpoint(with: self)
        async {
            return try solver.execute(query: query)
        }
    }
    
    
    open func verify(path: KBPath) async throws -> Bool {
        return try await self.backingStore.verify(path: path)
    }
}


// MARK: - TripleStore protocol
extension KBKnowledgeStore : TripleStore {
    public func insertTriple(withSubject subject: String, predicate: String, object: String) async throws {
        let subject = self.entity(withIdentifier: subject)
        let object = self.entity(withIdentifier: object)
        
        try await subject.link(to: object, withPredicate: predicate)
    }
}
