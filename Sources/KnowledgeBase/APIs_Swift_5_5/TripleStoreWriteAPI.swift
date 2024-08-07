import Foundation

extension KBKnowledgeStore {
    
    /**
     Remove the entity with a certain identifier.
     WARN: This will remove all the connections to this entity in the graph.
     
     - parameter identifier: the identifier
     */
    @objc public func removeEntity(_ identifier: Label) async throws {
        log.debug("remove [<\(identifier)> $? $?] or [$? $? <\(identifier)>]")
        
        let condition = KBGenericCondition.partialTripleHexaCondition(entityIdentifier: identifier)
        let _ = try await self.backingStore.removeValues(forKeysMatching: condition)
        self.delegate?.linkedDataDidChange()
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
        self.delegate?.linkedDataDidChange()
    }
    
    public func verify(path: KBPath) async throws -> Bool {
        return try await self.backingStore.verify(path: path)
    }
}

