//
//  TripleStoreWriteAPIs.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/18/21.
//

import RDFStorage

extension KBKnowledgeStore {
    
    /**
     Remove the entity with a certain identifier.
     WARN: This will remove all the connections to this entity in the graph.
     
     - parameter identifier: the identifier
     */
    open func removeEntity(_ identifier: Label, completionHandler: @escaping KBActionCompletion) {
        log.trace("[$? <\(identifier)> $?]")
        
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
        
        self.backingStore.removeValues(forKeysMatching: condition.rawCondition) { [weak self] result in
            self?.delegate?.linkedDataDidChange()
            switch result {
            case .failure(let err):
                completionHandler(.failure(err))
            case .success(_):
                completionHandler(.success(()))
            }
        }
    }
    
    open func importContentsOf(turtleFileAt path: String, completionHandler: @escaping KBActionCompletion) {
        let solver = KBSPARQLEndpoint(with: self)
        solver.importTurtle(fromFileAt: path, completionHandler: completionHandler)
    }
    
    /**
     Executes the SPARQL SELECT query and returns all the bounded values in the projection.
     
     - parameter query: the SPARQL SELECT query to execute
     - parameter completionHandler: the callback method
     */
    open func execute(SPARQLQuery query: String, completionHandler: @escaping (Swift.Result<[Any], Error>) -> ()) {
        self.sparqlQueue.async {
            let solver = KBSPARQLEndpoint(with: self)
            
            // @synchronized(solver)
            objc_sync_enter(solver)
            defer { objc_sync_exit(solver) }
            
            log.debug("SPARQL query (\(query, privacy: .public)")
            do {
                let results = try solver.execute(query: query)
                completionHandler(.success(results))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
    
    open func verify(path: KBPath, completionHandler: @escaping (Swift.Result<Bool, Error>) -> ()) {
        self.backingStore.verify(path: path, completionHandler: completionHandler)
    }
}


// MARK: - TripleStore protocol
extension KBKnowledgeStore : TripleStore {
    public func insertTriple(withSubject subject: String, predicate: String, object: String, completionHandler: @escaping (Error?) -> ()) {
        let subject = self.entity(withIdentifier: subject)
        let object = self.entity(withIdentifier: object)
        
        subject.link(to: object, withPredicate: predicate) { result in
            switch result {
            case .failure(let err): completionHandler(err)
            case .success: completionHandler(nil)
            }
        }
    }
}
