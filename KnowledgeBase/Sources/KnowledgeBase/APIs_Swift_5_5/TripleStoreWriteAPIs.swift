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
    
    internal func execute(SPARQLQuery query: String, completionHandler: @escaping (Swift.Result<[Any], Error>) -> ()) {
        self.sparqlQueue.async {
            let solver = KBSPARQLEndpoint(with: self)
            
            // @synchronized(solver)
            objc_sync_enter(solver)
            defer { objc_sync_exit(solver) }
            
            log.debug("SPARQL query (%@)", query)
            do {
                let results = try solver.execute(query: query)
                completionHandler(.success(results))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
    
    /**
     Executes the SPARQL SELECT query and returns all the bounded values in the projection.
     
     - parameter query: the SPARQL SELECT query to execute
     */
    @objc open func execute(SPARQLQuery query: String) async throws -> [Any] {
        return try await KBModernAsyncMethodReturningInitiable { c in
            self.execute(SPARQLQuery: query, completionHandler: c)
        }
//        async let result = { () -> [Any] in
//            let solver = KBSPARQLEndpoint(with: self)
//            return try solver.execute(query: query)
//        }
//        return try await result()
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
