//
//  TripleStoreWriteAPIs.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/18/21.
//

//import RDFStorage

extension KBKnowledgeStore {
    
    /**
     Remove the entity with a certain identifier.
     WARN: This will remove all the connections to this entity in the graph.
     
     - parameter identifier: the identifier
     */
    public func removeEntity(_ identifier: Label, completionHandler: @escaping KBActionCompletion) {
        log.trace("remove [<\(identifier)> $? $?] or [<\(identifier)> $? $?]")
        
        self.entity(withIdentifier: identifier).remove { [weak self] result in
            switch result {
            case .failure(let err):
                completionHandler(.failure(err))
            case .success(_):
                completionHandler(.success(()))
                self?.delegate?.linkedDataDidChange()
            }
        }
    }
    
    /**
     Removes triples matching the condition passed as argument
     
     - parameter condition: the condition triples have to satisfy to be removed.
     - parameter completionHandler: the callback method
     */
    public func removeTriples(matching condition: KBTripleCondition,
                              completionHandler: @escaping KBActionCompletion)
    {
        log.trace("remove \(condition.rawCondition)")
        
        self.backingStore.removeValues(forKeysMatching: condition.rawCondition) { [weak self] result in
            switch result {
            case .failure(let err):
                completionHandler(.failure(err))
            case .success(_):
                completionHandler(.success(()))
                self?.delegate?.linkedDataDidChange()
            }
        }
    }
    
    public func verify(path: KBPath, completionHandler: @escaping (Swift.Result<Bool, Error>) -> ()) {
        self.backingStore.verify(path: path, completionHandler: completionHandler)
    }
}
