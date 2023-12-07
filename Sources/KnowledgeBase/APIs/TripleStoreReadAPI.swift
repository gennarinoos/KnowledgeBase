//
//  TripleStoreReadAPIs.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/18/21.
//

import Foundation

extension KBKnowledgeStore {
    /**
     Returns all entities in the graph.
     
     - parameter completionHandler: the callback method
     
     */
    public func entities(completionHandler: @escaping (Swift.Result<[KBEntity], Error>) -> ()) {
        var uniqueIDs = Set<Label>()
        
        self.backingStore.values() { result in
            switch result {
            case .success(let values):
                for value in values {
                    if let triple = value as? KBTriple {
                        uniqueIDs.insert(triple.subject)
                        uniqueIDs.insert(triple.object)
                    }
                }
                completionHandler(.success(uniqueIDs.map {
                    self.entity(withIdentifier: $0)
                }))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    /**
     Removes triples matching the condition passed as argument
     
     - parameter condition: the condition triples have to satisfy to be removed.
     - parameter completionHandler: the callback method
     */
    public func triples(matching condition: KBTripleCondition?,
                      completionHandler: @escaping (Swift.Result<[KBTriple], Error>) -> ())
    {
        self.backingStore.triplesComponents(matching: condition, completionHandler: completionHandler)
    }
    
}
