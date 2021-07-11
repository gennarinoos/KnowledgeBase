//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/28/21.
//

import Foundation


extension KBEntity {
    
    /// Check if any KBRuleBasedLogic is satisfied.
    /// If so, infer the links or execute CKExecutableClosure behavior as defined by the rule.
    /// See CKKnowledgeStore::inferLink and CKKnowledgeStore::executeBehavior
    /// - Parameters:
    ///   - target: the entity being linked to this entity
    ///   - completionHandler: the completion handler
    internal func linkBasedOnRules(afterConnecting target: KBEntity) async throws {
        
        let satisfiableRules = try await self.satisfiableRules(afterConnecting: target)
        
        if satisfiableRules.count == 0 {
            return
        }
        
        for rule in satisfiableRules {
            if rule.predicate.beginsWith(CLOSURE_PREFIX) {
                assert(rule.predicate.endIndex > CLOSURE_PREFIX.endIndex)
                let closureIdentifier = String(rule.predicate[CLOSURE_PREFIX.endIndex...])

                if let data = try await self.store.value(forKey: closureIdentifier) as? Data {
                    if let closure = NSKeyedUnarchiver.unarchiveObject(with: data)
                        as? KBExecutableClosure {
                        log.debug("executing behavior %@ fired by linking [<%{private}@> <%{private}@> <%{private}@>]",
                            closure.identifier,
                            self,
                            rule.predicate,
                            target
                        )
                        closure.execute()
                    } else {
                        log.error("bad data for %@", closureIdentifier)
                        throw KBError.unexpectedData(nil)
                    }
                    throw KBError.notSupported
                }
            } else {
                try await self.link(to: rule.object, withPredicate: rule.predicate)
            }
        }
    }
    
    private func nonNegatedRuleComponentsAreSatisfied(inRule ruleEntity: KBEntity) async throws -> Bool {
        let nonNegatedRuleComponents = try await ruleEntity.linkingEntities(withPredicate: NEGATION_PREFIX, matchType: .beginsWith, complement: true)
        
        if nonNegatedRuleComponents.count == 0 {
            return true
        }
        
        var ruleSatisfied = true
        for ruleBody in nonNegatedRuleComponents {
            let existsCondition = KBTripleCondition(
                subject: self.identifier,
                predicate: ruleBody.predicate,
                object: ruleBody.subject.identifier
            )
            
            let triples = try await self.store.triples(matching: existsCondition)
            
            if triples.count == 0 {
                ruleSatisfied = false
                break
            }
        }
        
        return ruleSatisfied
    }
    
    private func negatedRuleComponentsAreSatisfied(inRule ruleEntity: KBEntity) async throws -> Bool {
        let negatedRuleComponents = try await ruleEntity.linkingEntities(
            withPredicate: NEGATION_PREFIX,
            matchType: .beginsWith)
        
        if negatedRuleComponents.count == 0 {
            return true
        }
        
        var ruleSatisfied = true
        for negatedRuleBody in negatedRuleComponents {
            assert(negatedRuleBody.predicate.beginsWith(NEGATION_PREFIX))
            assert(negatedRuleBody.predicate.endIndex > NEGATION_PREFIX.endIndex)
            let predicate = String(negatedRuleBody.predicate[NEGATION_PREFIX.endIndex...])
            
            let notExistsCondition = KBTripleCondition(
                subject: self.identifier,
                predicate: predicate,
                object: negatedRuleBody.subject.identifier
            )
            
            let triples = try await self.store.triples(matching: notExistsCondition)
            if triples.count > 0 {
                ruleSatisfied = false
                break
            }
        }
        
        return ruleSatisfied
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
            return []
        }
        
        // For each rule …
        for rule in ruleTriplesFromTarget {
            let ruleEntity = self.store.entity(withIdentifier: rule.object)
        
            // … check all the REQUIRED links are there …
            if try await self.nonNegatedRuleComponentsAreSatisfied(inRule: ruleEntity) == false {
                // … and terminate early if there is some!
                continue
            }
            
            // … then check all the NOT condition of the rule are satisfied (links are NOT there) …
            if try await self.negatedRuleComponentsAreSatisfied(inRule: ruleEntity) == false {
                // … and terminate early if there is some!
                continue
            }
            
            // Now if the rule is satisfied, retrieve all the links to infer
            inferredLinks += try await ruleEntity.linkedEntities()
        }
        
        return inferredLinks
    }
}
