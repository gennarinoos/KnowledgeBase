//
//  TripleStoreWriteAPIs.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/18/21.
//

import Foundation

extension KBKnowledgeStore {
    
    /**
     Remove the entity with a certain identifier.
     WARN: This will remove all the connections to this entity in the graph.
     
     - parameter identifier: the identifier
     */
    @objc public func removeEntity(_ identifier: Label) async throws {
        log.debug("remove [$? <\(identifier)> $?]")
        
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
        
        let _ = try await self.backingStore.removeValues(forKeysMatching: condition.rawCondition)
        self?.delegate?.linkedDataDidChange()
    }
    
    /**
     Matches triples need against the condition passed as argument
     
     - parameter condition: matches only triples having satisfying this condition.
     If nil, matches all triples
     - parameter completionHandler: the callback method
     */
    public func removeTriples(matching condition: KBTripleCondition) async throws
    {
        log.trace("remove \(condition.rawCondition)")
        let _ = try await self.backingStore.removeValues(forKeysMatching: condition.rawCondition)
        self?.delegate?.linkedDataDidChange()
    }
    
    public func verify(path: KBPath) async throws -> Bool {
        return try await self.backingStore.verify(path: path)
    }
}

