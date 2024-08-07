import Foundation

extension KBEntity {
    
    // MARK: KBEntity attributes
    
    @objc public func value(forAttribute key: String) async throws -> Any? {
        let key = KBHexastore.JOINER.combine(self.identifier, key)
        return try await self.store.value(for: key)
    }
    
    @objc public func set(
        value: Any,
        forAttribute key: String
    ) async throws {
        let writeBatch = self.store.backingStore.writeBatch()
        let entityKey = KBHexastore.JOINER.combine(self.identifier, key)
        writeBatch.set(value: value, for: entityKey)
        try await writeBatch.write()
    }
    
    @objc public func setAttributes(_ keysAndValues: [String: Any]) async throws {
        let writeBatch = self.store.backingStore.writeBatch()
        for (key, value) in keysAndValues {
            let entityKey = KBHexastore.JOINER.combine(self.identifier, key)
            writeBatch.set(value: value, for: entityKey)
        }
        
        try await writeBatch.write()
    }

    @objc public func removeAttribute(named key: String) async throws {
        let entityKey = KBHexastore.JOINER.combine(self.identifier, key)
        try await self.store.removeValue(for: entityKey)
    }


    // MARK: Linking/Unlinking

    /**
     Create a labeled connection between this KBEntity and the one passed as parameter

     If the target object has any watcher attached then these will all fire

     - parameter target: the KBEntity to connect to
     - parameter predicate: the label on the link
     - parameter completionHandler: the callback method
     
     */
    @objc public func link(
        to target: KBEntity,
        withPredicate predicate: Label
    ) async throws {
        log.trace("Linking [<\(self)> <\(predicate)> <\(target)>]")

        let subject = self.identifier
        let predicate = predicate
        let object = target.identifier
        
        let newWeight = try await self.store.backingStore.increaseWeight(
            forLinkWithLabel: predicate,
            between: subject,
            and: object
        )
        
        log.debug("New weight for triple [<\(self)> <\(predicate)> <\(target)>]: \(newWeight, privacy: .public)")
        
        try await self.linkBasedOnRules(afterConnecting: target)
        self.store.delegate?.linkedDataDidChange()
    }
    
    /**
     Remove the link from this KBEntity to the one passed as argument, that matches a certain predicate label

     - parameter target: the matching object
     - parameter label: the matching predicate
     - parameter ignoreWeights: if true, removes the links regardless of their weight, otherwise decrements the weight value. Links with weight 0 will be removed
     - parameter completionHandler: the callback method

     */
    public func unlink(
        to target: KBEntity,
        withPredicate label: Label,
        ignoreWeights: Bool = false
    ) async throws {
        if ignoreWeights {
            try await self.store.backingStore.dropLink(
                withLabel: label,
                between: self.identifier,
                and: target.identifier
            )
            log.debug("Deleted link [<\(self)> <\(label)> <\(target)>]")
        } else {
            let newWeight = try await self.store.backingStore.decreaseWeight(
                forLinkWithLabel: label,
                between: self.identifier,
                and: target.identifier
            )
            log.debug("New weight for triple [\(self)> <\(label)> <\(target)>]: \(newWeight, privacy: .public)")
        }
        self.store.delegate?.linkedDataDidChange()
    }
    
    /**
     Remove the entity from the graph
     */
    public func remove() async throws {
        try await self.store.backingStore.dropLinks(fromAndTo: self.identifier)
        self.store.delegate?.linkedDataDidChange()
    }
}


extension KBEntity {

    // MARK: Reachability

    /**
     Reachability from this KBEntity and the one passed as argument

     - parameter target: the KBEntity to connect to
     - parameter radius: limits the search to a particular radius
     (1 means directly connected)

     - returns: The path (a series of triples) connecting the two enties
     if such path exists, nil otherwise
     */
    public func path(to target: KBEntity,
                   withRadius radius: Int) async throws -> [(Label, Label)] {
        var radius = radius
        return try await self.path(to: target, radius: &radius)
    }

    fileprivate func path(to target: KBEntity,
                          radius: inout Int) async throws -> [(Label, Label)] {
        throw KBError.notSupported
//        guard radius > 0 else {
//            let error = KBError.fatalError("path search with negative radius doesn't make sense")
//            log.fault("\(error.localizedDescription, privacy: .public)")
//            throw error
//        }
//
//        log.debug("[<\(self)> * <\(target)>]")
//
//        var couplePath: [(Label, Label)] = []
//        let directLinks = try await self.linkedEntities()
//
//        for directLink in directLinks {
//            let linkedEntity: KBEntity = directLink.1
//            if (linkedEntity == target) {
//                couplePath.append((self.identifier, linkedEntity.identifier));
//            }
//        }
//
//        if (couplePath.count > 0) {
//            return couplePath
//        } else if (radius < 2) {
//            return []
//        } else {
//            if (radius > 10) {
//                log.trace("requested reachability with radius \(radius, privacy: .public) > 10")
//                log.debug("force setting radius. \(radius, privacy: .public) => 10")
//                radius = 10
//            }
//
//            let directlyLinkedEntities = directLinks.map { $0.object }
//            var _radius_copy = radius - 1
//
//            for entity in directlyLinkedEntities {
//                let subPaths = try await entity.path(to: target, radius: &_radius_copy)
//
//                couplePath.append((self.identifier, entity.identifier))
//                for subPath in subPaths {
//                    couplePath.append(subPath)
//                }
//            }
//
//            return couplePath
//        }
    }
}

extension KBEntity {

    // MARK: Linked entities

    /**
     Returns an array of KBEntity objects `self` is connected to

     The predicate label needs to match the one passed as argument

     - parameter predicate: constraints the search to a specific predicate label
     - parameter matchType: (defaults .equal) defines the match type on the predicate label.
     Note: only .equal and .beginsWith are supported
     - parameter complement: (defaults false) if true returns the complementary set
     
     */
    public func linkedEntities(
        withPredicate predicate: Label,
        matchType: KBMatchType = .equal,
        complement wantsComplementarySet: Bool = false
    ) async throws -> [(predicate: Label, object: KBEntity)] {
        let negatedFlag = wantsComplementarySet  == true ? "NOT " : ""
        log.trace("\(negatedFlag, privacy: .public)[<\(self)> <\(predicate):\(matchType.description, privacy: .public)> $?]")
        
        var condition: KBTripleCondition
        
        switch matchType {
        case .beginsWith:
            let partial = KBHexastore.JOINER.combine(
                KBHexastore.SPO.rawValue,
                self.identifier,
                predicate
            )
            let matches = KBTripleCondition(KBGenericCondition(.beginsWith, value: partial))
            if wantsComplementarySet {
                let relaxedPartial = KBHexastore.JOINER.combine(
                    KBHexastore.SPO.rawValue,
                    self.identifier,
                    end: true
                )
                let matchesRelaxed = KBTripleCondition(KBGenericCondition(
                    .beginsWith,
                    value: relaxedPartial
                ))
                condition = not(matches).and(matchesRelaxed)
            } else {
                condition = matches
            }
        case .equal:
            if wantsComplementarySet {
                condition = KBTripleCondition(
                    KBGenericCondition(
                        .beginsWith,
                        value: KBHexastore.JOINER.combine(
                            KBHexastore.SPO.rawValue,
                            self.identifier,
                            end: true
                        )
                    ).and(KBGenericCondition(
                        .beginsWith,
                        value: KBHexastore.JOINER.combine(
                            KBHexastore.SPO.rawValue,
                            self.identifier,
                            predicate,
                            end: true
                        ),
                        negated: true
                    ))
                )
            } else {
                condition = KBTripleCondition(
                    subject: self.identifier,
                    predicate: predicate,
                    object: nil
                )
            }
        default:
            throw KBError.notSupported
        }

        return try await self.store.triples(matching: condition)
            .map { triple in
                (
                    predicate: triple.predicate,
                    object: self.store.entity(withIdentifier: triple.object)
                )
            }
    }
    
    /**
     Returns all KBEntity objects `self` is connected to, and their labeled connections.
     Blocking version
     
     There can be many labeled connections between two entities,
     each having either a different predicate label, or a different target entity (object)
     
     - returns: An array of tuples (predicate: P, object: O)
     
     */
    public func linkedEntities() async throws -> [(predicate: Label, object: KBEntity)] {
        log.trace("[<\(self)> $? $?]")

        let condition = KBTripleCondition(subject: self.identifier, predicate: nil, object: nil)

        let triples = try await self.store.triples(matching: condition)
        return triples.map { triple in 
            (
                predicate: triple.predicate,
                object: self.store.entity(withIdentifier: triple.object)
            )
        }
    }
    

    // MARK: Linking entities

    /**
     Returns an array of KBEntity objects this KBEntity is directly reachable from
     
     The predicate label needs to match exactly the one passed as argument
     
     - parameter predicate: constraints the search to a specific predicate label
     - parameter matchType: (defaults .Equal) defines the match type
     on the predicate label
     - parameter complement: (defaults false) if true returns the complementary set
     
     - returns: The array of KBEntity objects matching the condition
     
     */
    public func linkingEntities(
        withPredicate predicate: Label,
        matchType: KBMatchType = .equal,
        complement wantsComplementarySet: Bool = false
    ) async throws -> [(subject: KBEntity, predicate: Label)] {
        let negatedFlag = wantsComplementarySet ? "NOT " : ""
        log.trace("\(negatedFlag, privacy: .public)[$? <\(predicate):\(matchType.description, privacy: .public)> <\(self)>]")

        var condition: KBTripleCondition

        switch matchType {
        case .beginsWith:
            let partial = KBHexastore.JOINER.combine(
                KBHexastore.OPS.rawValue,
                self.identifier,
                predicate
            )
            let matches = KBTripleCondition(KBGenericCondition(.beginsWith, value: partial))
            if wantsComplementarySet {
                let relaxedPartial = KBHexastore.JOINER.combine(
                    KBHexastore.OPS.rawValue,
                    self.identifier,
                    end: true
                )
                let matchesRelaxed = KBTripleCondition(KBGenericCondition(
                    .beginsWith,
                    value: relaxedPartial
                ))
                condition = not(matches).and(matchesRelaxed)
            } else {
                condition = matches
            }
        case .equal:
            if wantsComplementarySet {
                condition = KBTripleCondition(
                    KBGenericCondition(
                        .beginsWith,
                        value: KBHexastore.JOINER.combine(
                            KBHexastore.OPS.rawValue,
                            self.identifier,
                            end: true
                        )
                    ).and(KBGenericCondition(
                        .beginsWith,
                        value: KBHexastore.JOINER.combine(
                            KBHexastore.OPS.rawValue,
                            self.identifier,
                            predicate,
                            end: true
                        ),
                        negated: true
                    ))
                )
            } else {
                condition = KBTripleCondition(
                    subject: nil,
                    predicate: predicate,
                    object: self.identifier
                )
            }
        default:
            throw KBError.notSupported
        }
        
        return try await self.store.triples(matching: condition)
            .map { triple in
                (
                    subject: self.store.entity(withIdentifier: triple.subject),
                    predicate: triple.predicate
                )
            }
    }
    
    /**
     Returns all KBEntity objects this KBEntity is directly reachable from,
     and their labeled connections
     
     There can be many labeled connections between two entities,
     each having either a different predicate label, or a different target entity (object)
     
     - returns: An array of tuples (predicate: P, object: O)
     
     */
    public func linkingEntities() async throws -> [(subject: KBEntity, predicate: Label)] {
        log.debug("[$? $? <\(self)>]")

        let condition = KBTripleCondition(subject: nil, predicate: nil, object: self.identifier)
        let triples = try await self.store.triples(matching: condition)
        return triples.map { triple in
            (
                subject: self.store.entity(withIdentifier: triple.subject),
                predicate: triple.predicate
            )
        }
    }

    // MARK: Links
    
    /**
     Returns all the predicate labels connecting `this` KBEntity,
     and the one passed as argument
     
     - parameter target: constraints the query to a particular KBEntity
     
     - returns: The array of predicate labels
     */
    @objc public func links(to target: KBEntity) async throws -> [Label] {
        log.debug("[<\(self)> $? <\(target)>]")

        let condition = KBTripleCondition(subject: self.identifier, predicate: nil, object: target.identifier)
        return try await self.store.triples(matching: condition)
            .map { triple in triple.predicate }
    }
}


extension KBEntity {
    
    
    /// Check if any KBLogic is satisfied.
    /// If so, infer the links or execute KBExecutableClosure behavior as defined by the rule.
    /// See KBKnowledgeStore::inferLink and KBKnowledgeStore::executeBehavior
    /// - Parameters:
    ///   - target: the entity being linked to this entity
    ///   - completionHandler: the completion handler
    internal func linkBasedOnRules(afterConnecting target: KBEntity) async throws {
        
        let satisfiableRules = try await self.satisfiableRules(afterConnecting: target)
        
        guard satisfiableRules.isEmpty == false else {
            return
        }
        
        for rule in satisfiableRules {
            if rule.predicate.beginsWith(CLOSURE_PREFIX) {
//                    assert(rule.predicate.endIndex > CLOSURE_PREFIX.endIndex)
//                    let closureIdentifier = rule.predicate.substring(from: CLOSURE_PREFIX.endIndex)
//
//                    if let data = self.store._value(forKey: closureIdentifier) as? Data {
//                        if let closure = NSKeyedUnarchiver.unarchiveObject(with: data)
//                            as? KBExecutableClosure {
//                            log.debug("executing behavior \(closure.identifier, privacy: .public) fired by linking [<\(self)> <\(rule.predicate)> <\(target)>]")
//                            closure.execute()
//                        } else {
//                            log.error("bad data for \(closure.identifier, privacy: .public)")
//                            dispatch.interrupt(KBError.unexpectedData)
//                        }
//                        dispatch.interrupt(KBError.notSupported)
//                    }
            } else {
                try await self.link(
                    to: rule.object,
                    withPredicate: rule.predicate)
            }
        }
    }
    
    private func nonNegatedRuleComponentsAreSatisfied(inRule ruleEntity: KBEntity) async throws -> Bool {
        let nonNegatedRuleComponents = try await ruleEntity.linkingEntities(
            withPredicate: NEGATION_PREFIX,
            matchType: .beginsWith,
            complement: true
        )
        guard nonNegatedRuleComponents.isEmpty == false else {
            return true
        }
        
        for ruleBody in nonNegatedRuleComponents {
            let existsCondition = KBTripleCondition(
                subject: self.identifier,
                predicate: ruleBody.predicate,
                object: ruleBody.subject.identifier
            )
            
            let triples = try await self.store.triples(matching: existsCondition)
            if triples.count == 0 {
                return false
            }
        }
        
        return true
    }
    
    private func negatedRuleComponentsAreSatisfied(inRule ruleEntity: KBEntity) async throws -> Bool {
        let negatedRuleComponents = try await ruleEntity.linkingEntities(
            withPredicate: NEGATION_PREFIX,
            matchType: .beginsWith
        )
        
        guard negatedRuleComponents.isEmpty == false else {
            return true
        }
        
        for negatedRuleBody in negatedRuleComponents {
            assert(negatedRuleBody.predicate.beginsWith(NEGATION_PREFIX))
            assert(negatedRuleBody.predicate.endIndex > NEGATION_PREFIX.endIndex)
            let predicate = String(negatedRuleBody.predicate[NEGATION_PREFIX.endIndex...])
            
            let notExistsCondition = KBTripleCondition(
                subject: self.identifier,
                predicate: predicate,
                object: negatedRuleBody.subject.identifier
            )
            
            let triples = try await self.store.triples(
                matching: notExistsCondition
            )
            
            if triples.count > 0 {
                return false
            }
        }
        
        return true
    }
    
    /**
     Get all the triples having subject this KBEntity and predicate
     WHERE [subject=self.identifier, predicate="$(NEGATION_PREFIX)?$(RULE_PREFIX)*", object=?]
     GROUP BY predicate, object
     
     - parameter afterConnecting: the entity `this` has just been connected to
     - parameter completionHandler: the callback method
     */
    private func satisfiableRules(afterConnecting entity: KBEntity) async throws -> [(predicate: Label, object: KBEntity)] {
        var inferredLinks = [(predicate: Label, object: KBEntity)]()
        let allRulesFromTarget = KBTripleCondition.forRules(from: entity)
        
        let triplesFromTarget = try await self.store.triples(matching: allRulesFromTarget)
        
        // FIXME: This filter should be done on DB
        let ruleTriplesFromTarget = triplesFromTarget.filter {
            $0.object.beginsWith(RULE_PREFIX) ||
                $0.object.beginsWith(NEGATION_PREFIX, RULE_PREFIX)
        }
        
        if ruleTriplesFromTarget.count == 0 {
            return inferredLinks
        }
        
        // For each rule …
        for rule in ruleTriplesFromTarget {
            let ruleEntity = self.store.entity(withIdentifier: rule.object)
            
            // … check all the REQUIRED links are there …
            guard try await self.nonNegatedRuleComponentsAreSatisfied(inRule: ruleEntity) == true
            else {
                // … and terminate early if some is missing!
                return inferredLinks
            }
            
            // … then check all the NOT condition of the rule are satisfied (links are NOT there) …
            guard try await self.negatedRuleComponentsAreSatisfied(inRule: ruleEntity) == true
            else {
                // … and terminate early if there is some!
                return inferredLinks
            }
            
            // Now if the rule is satisfied, retrieve all the links to infer
            let linkedEntities = try await ruleEntity.linkedEntities()
            inferredLinks += linkedEntities
        }
        
        return inferredLinks
    }
}
