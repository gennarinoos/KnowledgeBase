//
//  Entity.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/22/21.
//

import Foundation


@objc(KBEntity)
open class KBEntity : NSObject {
    public let identifier: Label
    let store: KBKnowledgeStore

    internal init(identifier id: Label, knowledgeStore: KBKnowledgeStore) {
        self.identifier = id
        self.store = knowledgeStore
    }

    // MARK: Hashable, Equatable protocol

    @objc open override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? KBEntity {
            return self.store.isEqual(object.store)
                && self.identifier == object.identifier
        }
        return false
    }
    
    @objc open override var hash: Int {
        return (self.store.name.hashValue
            ^ self.identifier.hashValue);
    }

    // MARK: CustomStringConvertible protocol

    @objc open override var description: String {
        return self.identifier
    }

    // MARK: KBEntity attributes
    
    @objc open func value(forKey key: String) async throws -> Any? {
        let key = KBHexastore.JOINER.combine(self.identifier, key)
        return await self.store.value(forKey: key)
    }
    
    @objc open func values(forKeys keys: [String]) async throws -> [Any?] {
        let keys = keys.map { KBHexastore.JOINER.combine(self.identifier, $0) }
        return self.store.values(forKeys: keys, completionHandler: completionHandler)
    }
    
    @objc open func setValue(_ value: Any,
                             forKey key: String) async throws {
        let writeBatch = self.store.backingStore.writeBatch()
        let entityKey = KBHexastore.JOINER.combine(self.identifier, key)
        writeBatch.setObject(value, forKey: entityKey)
        writeBatch.write() {
            error in
            if error != nil {
                log.error("error attaching attribute \"%{private}@\" to entity %{private}@ (key=%{private}@). %@",
                          "\(value)", self.identifier, entityKey, error!.localizedDescription)
            }
            completionHandler(error)
        }
    }
    
    @objc open func setValues(forKeys keysAndValues: [String: Any],
                              completionHandler: @escaping CKActionCompletion) {
        let writeBatch = self.store.backingStore.writeBatch()
        for (key, value) in keysAndValues {
            let entityKey = KBHexastore.JOINER.combine(self.identifier, key)
            writeBatch.setObject(value, forKey: entityKey)
        }
        
        writeBatch.write() {
            error in
            if error != nil {
                log.error("error attaching attributes \"%{private}@\" to entity %{private}@. %@",
                          keysAndValues, self, error!.localizedDescription)
            }
            completionHandler(error)
        }
    }

    @objc open func removeValue(forKey key: String, completionHandler: @escaping CKActionCompletion) {
        let entityKey = KBHexastore.JOINER.combine(self.identifier, key)
        self.store.removeValue(forKey: entityKey, completionHandler: completionHandler)
    }


    // MARK: Linking/Unlinking

    /**
     Create a labeled connection between this KBEntity and the one passed as parameter

     If the target object has any watcher attached then these will all fire

     - parameter target: the KBEntity to connect to
     - parameter predicate: the label on the link
     - parameter completionHandler: the code to execute when the link has been set
     */
    @objc open func link(to target: KBEntity,
                         withPredicate predicate: Label,
                         completionHandler: @escaping CKActionCompletion) {
        log.debug("[<%{private}@> <%{private}@> <%{private}@>]",
                  self, predicate, target)

        let subject = self.identifier
        let predicate = predicate
        let object = target.identifier
        
        let dispatch = CKTimedDispatch()

        // Increment the weight of the link and update the hexastore
        self.store.backingStore.increaseWeight(forLinkWithLabel: predicate,
                                               between: subject,
                                               and: object) {
            (error: Error?, weight: Int) in
            if let err = error {
                dispatch.interrupt(err)
                return
            }
            
            dispatch.semaphore.signal()
        }
        
        // When the write batch is done, propagate links based on rules
        do {
            try dispatch.wait()
            self.linkBasedOnRules(afterConnecting: target, completionHandler: completionHandler)
        } catch {
            completionHandler(error)
        }
    }
    
    /**
     Create a labeled connection between this KBEntity and the one passed as parameter
     
     If the target object has any watcher attached then these will all fire
     
     - parameter target: the KBEntity to connect to
     - parameter predicate: the label on the link
     */
    @objc open func link(to target: KBEntity,
                         withPredicate predicate: Label) throws {
        try CKDispatchSemaphoreReturningVoid {
                (completionHandler: @escaping (Error?) -> ()) in
                self.link(to: target, withPredicate: predicate) { completionHandler($0) }
        }
    }
    
    /**
     Remove the link from this KBEntity to the one passed as argument, that matches a certain predicate label

     - parameter target: the matching object
     - parameter label: the matching predicate
     - parameter ignoreWeights: if true, removes the links regardless of their weight, otherwise decrements the weight value. Links with weight 0 will be removed
     - parameter completionHandler: the callback method
     */
    @objc open func unlink(to target: KBEntity,
                           withPredicate label: Label,
                           ignoreWeights: Bool = false,
                           completionHandler: @escaping CKActionCompletion) {
        if ignoreWeights {
            self.store.backingStore.dropLink(withLabel: label,
                                             between: self.identifier,
                                             and: target.identifier,
                                             completionHandler: completionHandler)
        } else {
            self.store.backingStore.decreaseWeight(forLinkWithLabel: label,
                                                   between: self.identifier,
                                                   and: target.identifier,
                                                   completionHandler: {
                                                    (err, _) in
                                                    completionHandler(err)
            })
        }
    }
    
    /**
     Remove the link from this KBEntity to the one passed as argument, that matches a certain predicate label
     
     - parameter target: the matching object
     - parameter label: the matching predicate
     - parameter ignoreWeights: if true, removes the links regardless of their weight, otherwise decrements the weight value. Links with weight 0 will be removed
     */
    open func unlink(to target: KBEntity,
                     withPredicate label: Label,
                     ignoreWeights: Bool = false) throws {
        try CKDispatchSemaphoreReturningVoid {
            (completionHandler: @escaping (Error?) -> ()) in
            self.unlink(to: target,
                        withPredicate: label,
                        ignoreWeights: ignoreWeights,
                        completionHandler: completionHandler)
        }
    }
    
    /**
     Remove the entity from the graph
     - parameter completionHandler: the callback method
     */
    @objc open func remove(completionHandler: @escaping CKActionCompletion) {
        self.store.backingStore.dropLinks(withLabel: nil, from: self.identifier, completionHandler: completionHandler)
    }
    
    /**
     Remove the entity from the graph
     */
    open func remove() throws {
        try CKDispatchSemaphoreReturningVoid {
            (completionHandler: @escaping (Error?) -> ()) in
            self.remove(completionHandler: completionHandler)
        }
    }


    // MARK: Reachability

    /**
     Reachability from this KBEntity and the one passed as argument

     - parameter target: the KBEntity to connect to
     - parameter radius: limits the search to a particular radius
     (1 means directly connected)

     - returns: The path (a series of triples) connecting the two enties
     if such path exists, nil otherwise
     */
    open func path(to target: KBEntity,
                   withRadius radius: Int,
                   completionHandler: @escaping (Error?, [(Label, Label)]) -> ()) {
        let queue = DispatchQueue(label: "\(KnowledgeBaseBundleIdentifier).KBEntity.path", attributes: .concurrent)
        weak var welf = self
        queue.async {
            var radius = radius
            do {
                completionHandler(nil, try welf?.path(to: target, radius: &radius) ?? [])
            } catch {
                completionHandler(error, [])
            }
        }
    }
    
    open func path(to target: KBEntity,
                   withRadius radius: Int) throws -> [(Label, Label)] {
        var radius = radius
        return try self.path(to: target, radius: &radius)
    }

    fileprivate func path(to target: KBEntity,
                          radius: inout Int) throws -> [(Label, Label)] {
        guard radius > 0 else {
            let error = KBError.fatalError("path search with negative radius doesn't make sense")
            log.fault("%@", error.localizedDescription)
            throw error
        }

        log.debug("[<%{private}@> * <%{private}@>]", self, target)

        var couplePath: [(Label, Label)] = []
        let directLinks = try self.linkedEntities()

        for directLink in directLinks {
            let linkedEntity: KBEntity = directLink.1
            if (linkedEntity == target) {
                couplePath.append((self.identifier, linkedEntity.identifier));
            }
        }

        if (couplePath.count > 0) {
            return couplePath
        } else if (radius < 2) {
            return []
        } else {
            if (radius > 10) {
                log.info("requested reachability with radius %@ > 10", radius)
                log.info("force setting radius. %@ => 10", radius)
                radius = 10
            }

            let directlyLinkedEntities = directLinks.map { $0.object }
            var _radius_copy = radius - 1

            for entity in directlyLinkedEntities {
                let subPaths = try entity.path(to: target, radius: &_radius_copy)

                couplePath.append((self.identifier, entity.identifier))
                for subPath in subPaths {
                    couplePath.append(subPath)
                }
            }

            return couplePath
        }
    }


    // MARK: Linked entities

    /**
     Returns an array of KBEntity objects `self` is connected to

     The predicate label needs to match the one passed as argument

     - parameter predicate: constraints the search to a specific predicate label
     - parameter matchType: (defaults .equal) defines the match type on the predicate label.
     Note: only .equal and .beginsWith are supported
     - parameter complement: (defaults false) if true returns the complementary set
     - parameter completionHandler: the callback method
     */
    open func linkedEntities(withPredicate predicate: Label,
                             matchType: KBMatchType = .equal,
                             complement wantsComplementarySet: Bool = false,
                             completionHandler:@escaping (Error?, [(predicate: Label, object: KBEntity)]) -> ()) {
        let negatedFlag = wantsComplementarySet  == true ? "NOT " : ""
        log.debug("%@[<%{private}@> <%{private}@:%@> $?]",
                  negatedFlag, self, predicate, matchType.description)

        var partial = KBHexastore.JOINER.combine(KBHexastore.SPO.rawValue, self.identifier)

        switch (wantsComplementarySet, matchType) {
        case (false, let match) where match == .equal || match == .beginsWith:
            partial = KBHexastore.JOINER.combine(partial, predicate, end: true)
        case(true, .equal):
            partial += KBHexastore.JOINER
        case(_, .beginsWith):
            break
        default:
            completionHandler(KBError.notSupported, [])
            return
        }

        var condition = KBTripleCondition(KBGenericCondition(.beginsWith, value: partial))
        if wantsComplementarySet  {
            let value = partial + (matchType == .beginsWith ? KBHexastore.JOINER + predicate : predicate + KBHexastore.JOINER)
            let matchesLabel = KBTripleCondition(KBGenericCondition(.beginsWith, value: value))
            condition = condition.and(not(matchesLabel))
        }

        self.store.triples(matching: condition) {
            (error: Error?, triples: [KBTriple]) in
            completionHandler(error, triples.map {
                triple in
                (predicate: triple.predicate, object: self.store.entity(withIdentifier: triple.object))
            })
        }
    }
    
    /**
     Returns an array of KBEntity objects `self` is connected to.
     Blocking version.
     
     The predicate label needs to match the one passed as argument
     
     - parameter predicate: constraints the search to a specific predicate label
     - parameter matchType: (defaults .equal) defines the match type on the predicate label.
     Note: only .equal and .beginsWith are supported
     - parameter complement: (defaults false) if true returns the complementary set
     
     - returns: the array of KBEntity objects `self` is connected to
     */
    open func linkedEntities(withPredicate predicate: Label,
                             matchType: KBMatchType = .equal,
                             complement wantsComplementarySet: Bool = false) throws -> [(predicate: Label, object: KBEntity)] {
        return try CKDispatchSemaphoreReturningInitiable {
            (completionHandler: @escaping (Error?, [(predicate: Label, object: KBEntity)]) -> ()) in
            self.linkedEntities(withPredicate: predicate,
                                matchType: matchType,
                                complement: wantsComplementarySet,
                                completionHandler: completionHandler)
        }
    }

    /**
     Returns all KBEntity objects `self` is connected to, and their labeled connections

     There can be many labeled connections between two entities,
     each having either a different predicate label, or a different target entity (object)

     - parameter completionHandler: the callback method
     */
    open func linkedEntities(completionHandler: @escaping (Error?, [(predicate: Label, object: KBEntity)]) -> ()) {
        log.debug("[<%{private}@> $? $?]", self)

        let partial = KBHexastore.JOINER.combine(
            KBHexastore.SPO.rawValue,
            self.identifier,
            end: true
        )
        let condition = KBTripleCondition(KBGenericCondition(.beginsWith, value: partial))

        self.store.triples(matching: condition) {
            (error: Error?, triples: [KBTriple]) in
            if let _ = error {
                completionHandler(error, [])
            } else {
                completionHandler(nil, triples.map {
                    triple in (predicate: triple.predicate, object: self.store.entity(withIdentifier: triple.object))
                })
            }
        }
    }
    
    /**
     Returns all KBEntity objects `self` is connected to, and their labeled connections.
     Blocking version
     
     There can be many labeled connections between two entities,
     each having either a different predicate label, or a different target entity (object)
     
     - returns: An array of tuples (predicate: P, object: O)
     */
    open func linkedEntities() throws -> [(predicate: Label, object: KBEntity)] {
        return try CKDispatchSemaphoreReturningInitiable(execute: self.linkedEntities)
    }
    

    // MARK: Linking entities

    /**
     Returns an array of KBEntity objects this KBEntity is directly reachable from

     The predicate label needs to match exactly the one passed as argument

     - parameter predicate: constraints the search to a specific predicate label
     - parameter matchType: (defaults .Equal) defines the match type
     on the predicate label
     - parameter complement: (defaults false) if true returns the complementary set
     - parameter completionHandler: the callback method
     */
    open func linkingEntities(withPredicate predicate: Label,
                              matchType: KBMatchType = .equal,
                              complement wantsComplementarySet: Bool = false,
                              completionHandler: @escaping (Error?, [(subject: KBEntity, predicate: Label)]) -> ()) {
        let negatedFlag = wantsComplementarySet ? "NOT " : ""
        log.debug("%@[$? <%{private}@:%@> <%{private}@>]",
                  negatedFlag, predicate, matchType.description, self)

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
            let matches = KBTripleCondition(
                subject: nil,
                predicate: predicate,
                object: self.identifier
            )
            if wantsComplementarySet {
                let matchesRelaxed = KBTripleCondition(
                    subject: nil,
                    predicate: nil,
                    object: self.identifier
                )
                condition = not(matches).and(matchesRelaxed)
            } else {
                condition = matches
            }
            let beginsWithOPS = KBTripleCondition(KBGenericCondition(
                .beginsWith,
                value: KBHexastore.OPS.rawValue
            ))
            condition = condition.and(beginsWithOPS)
        default:
            completionHandler(KBError.notSupported, [])
            return
        }
        
        self.store.triples(matching: condition) {
            (error: Error?, triples: [KBTriple]) in
            if let _ = error {
                completionHandler(error, [])
            } else {
                completionHandler(nil, triples.map {
                    triple in (subject: self.store.entity(withIdentifier: triple.subject), predicate: triple.predicate)
                })
            }
        }
    }
    
    /**
     Returns an array of KBEntity objects this KBEntity is directly reachable from
     
     The predicate label needs to match exactly the one passed as argument
     
     - parameter predicate: constraints the search to a specific predicate label
     - parameter matchType: (defaults .Equal) defines the match type
     on the predicate label
     - parameter complement: (defaults false) if true returns the complementary set
     
     - returns: The array of KBEntity objects matching the condition
     */
    open func linkingEntities(withPredicate predicate: Label,
                              matchType: KBMatchType = .equal,
                              complement wantsComplementarySet: Bool = false) throws -> [(subject: KBEntity, predicate: Label)] {
        return try CKDispatchSemaphoreReturningInitiable {
            (completionHandler: @escaping (Error?, [(subject: KBEntity, predicate: Label)]) -> ()) in
            self.linkingEntities(withPredicate: predicate,
                                 matchType: matchType,
                                 complement: wantsComplementarySet,
                                 completionHandler: completionHandler)
        }
    }

    /**
     Returns all KBEntity objects this KBEntity is directly reachable from,
     and their labeled connections

     There can be many labeled connections between two entities,
     each having either a different predicate label, or a different target entity (object)
     
     - parameter completionHandler: the callback method
     */
    open func linkingEntities(completionHandler: @escaping (Error?, [(subject: KBEntity, predicate: Label)]) -> ()) {
        log.debug("[$? $? <%{private}@>]", self)

        let partial = KBHexastore.JOINER.combine(
            KBHexastore.OPS.rawValue,
            self.identifier,
            end: true
        )
        let condition = KBTripleCondition(KBGenericCondition(.beginsWith, value: partial))
        self.store.triples(matching: condition) {
            (error: Error?, triples: [KBTriple]) in
            if let _ = error {
                completionHandler(error, [])
            } else {
                completionHandler(nil, triples.map {
                    triple in (subject: self.store.entity(withIdentifier: triple.subject), predicate: triple.predicate)
                })
            }
        }
    }
    
    /**
     Returns all KBEntity objects this KBEntity is directly reachable from,
     and their labeled connections
     
     There can be many labeled connections between two entities,
     each having either a different predicate label, or a different target entity (object)
     
     - returns: An array of tuples (predicate: P, object: O)
     */
    open func linkingEntities() throws -> [(subject: KBEntity, predicate: Label)] {
        return try CKDispatchSemaphoreReturningInitiable(execute: self.linkingEntities)
    }

    // MARK: Links

    /**
     Returns all the predicate labels connecting `this` KBEntity,
     and the one passed as argument

     - parameter target: constraints the query to a particular KBEntity
     - parameter matchType: (defaults .Equal) defines the match type
     on the identifier of the linked KBEntity (target)
     - parameter completionHandler: the callback method
     */
    @objc open func links(to target: KBEntity,
                          matchType: KBMatchType = .equal,
                          completionHandler: @escaping (Error?, [Label]) -> ()) {
        log.debug("[<%{private}@> $? <%{private}@:%@>]",
                  self, target, matchType.description)

        let partial: String

        switch matchType {
        case .beginsWith:
            partial = KBHexastore.JOINER.combine(
                KBHexastore.SOP.rawValue,
                self.identifier,
                target.identifier
            )
        case .equal:
            partial = KBHexastore.JOINER.combine(
                KBHexastore.SOP.rawValue,
                self.identifier,
                target.identifier,
                end: true
            )
        default:
            completionHandler(KBError.notSupported, [])
            return
        }

        let condition = KBTripleCondition(KBGenericCondition(.beginsWith, value: partial))
        self.store.triples(matching: condition) {
            (error: Error?, triples: [KBTriple]) in
            if let _ = error {
                completionHandler(error, [])
            } else {
                completionHandler(nil, triples.map {
                    triple in triple.predicate
                })
            }
        }
    }
    
    /**
     Returns all the predicate labels connecting `this` KBEntity,
     and the one passed as argument
     
     - parameter target: constraints the query to a particular KBEntity
     - parameter matchType: (defaults .Equal) defines the match type
     on the identifier of the linked KBEntity (target)
     
     - returns: The array of predicate labels
     */
    @objc open func links(to target: KBEntity,
                          matchType: KBMatchType = .equal) throws -> [Label] {
        return try CKDispatchSemaphoreReturningInitiable {
            (completionHandler: @escaping (Error?, [Label]) -> ()) in
            self.links(to: target,
                       matchType: matchType,
                       completionHandler: completionHandler)
        }
    }
}

public func ==(lhs: KBEntity, rhs: KBEntity) -> Bool {
    return lhs.identifier == rhs.identifier
}

public func ==<T: KBEntity>(lhs: T, rhs: T) -> Bool {
    return lhs.identifier == rhs.identifier
}
