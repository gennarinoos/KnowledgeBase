//
//  KBCondition.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/19/21.
//

import Foundation

let _KBGenericCondition_enumType = "enumType"
let _KBGenericCondition_negated = "negated"
let _KBGenericCondition_matcherType = "matcherType"
let _KBGenericCondition_matcherValue = "matcherValue"
let _KBGenericCondition_this = "this"
let _KBGenericCondition_and = "and"
let _KBGenericCondition_or = "or"
let _KBTripleCondition_raw = "raw"


// MARK: - Triple Conditions

internal enum ConditionType : CustomStringConvertible {
    case none
    case simple(Matcher)
    case composite(KBGenericCondition, and: KBGenericCondition?, or: KBGenericCondition?)
    
    var stringValue: String {
        switch self {
        case .none: return "none"
        case .simple(_): return "simple"
        case .composite(_, and: _, or: _): return "composite"
        }
    }
    
    var description: String {
        let string = self.stringValue
        switch self {
        case .none: return string
        case .simple(let matcher):
            return "\(string)(\(matcher.comparison)=\(matcher.value))"
        case .composite(let this, and: let and, or: let or):
            return "\(string)(\(this),\(and?.description ?? ""),\(or?.description ?? ""))"
        }
    }
}

@objc public enum KBMatchType : Int, CustomStringConvertible {
    case beginsWith = 0, contains, endsWith, equal
    
    public var description: String {
        switch self {
        case .beginsWith: return "^"
        case .contains: return "*"
        case .endsWith: return "$"
        case .equal: return "="
        }
    }
}

internal class Matcher {
    
    let comparison: KBMatchType
    let value: String
    
    init(_ type: KBMatchType, value: String) {
        self.comparison = type
        self.value = value
    }
    
    func evaluate(on key: Any?) -> Bool {
        if let string = key as? String {
            switch self.comparison {
            case .beginsWith: return string.beginsWith(self.value)
            case .contains: return string.contains(self.value)
            case .equal: return string == self.value
            case .endsWith: return string.endsWith(self.value)
            }
        }
        return false
    }
    
    lazy var sql: String = {
        var sql = "k LIKE "
        switch self.comparison {
        case .beginsWith: sql += "\"\(self.value)%\""
        case .contains: sql += "\"%\(self.value)%\""
        case .equal: sql += "\"\(self.value)\""
        case .endsWith: sql += "\"%\(self.value)\""
        }
        return sql
    }()
}

@objc(KBGenericCondition)
public class KBGenericCondition : NSObject, NSCopying, NSSecureCoding {
    fileprivate let type : ConditionType
    fileprivate var negated : Bool
    
    @objc public var predicate: NSPredicate {
        get {
            return NSPredicate(block: { (key, _) in self.evaluate(on: key) })
        }
    }
    
    @objc public override var description: String {
        return "\(negated ? "!" : "")\(type)"
    }
    
    @objc public init(value: Bool) {
        self.type = .none
        self.negated = !value
    }
    
    @objc(initWithMatchType:value:negated:)
    public init(_ type: KBMatchType, value: String, negated: Bool = false) {
        self.type = .simple(Matcher(type, value: value))
        self.negated = negated
    }
    
    fileprivate init(_ s: KBGenericCondition, and: KBGenericCondition? = nil, or: KBGenericCondition? = nil, negated: Bool = false) {
        assert(and == nil || or == nil)
        if and == nil && or == nil {
            self.type = s.type
        } else {
            self.type = .composite(s, and: and, or: or)
        }
        self.negated = negated
    }
    
    @objc public func and(_ condition: KBGenericCondition) -> KBGenericCondition {
        switch self.type {
        case .none: return condition
        case .simple, .composite:
            switch condition.type {
            case .none: return self
            case .simple, .composite: return KBGenericCondition(self, and: condition, or: nil)
            }
        }
    }
    
    @objc public func or(_ condition: KBGenericCondition) -> KBGenericCondition {
        switch self.type {
        case .none: return condition
        case .simple, .composite:
            switch condition.type {
            case .none: return self
            case .simple, .composite: return KBGenericCondition(self, and: nil, or: condition)
            }
        }
    }
    
    /**
     The SQL representation of this condition
     */
    internal lazy var sql: String = {
        var sql = ""
        switch self.type {
        case .none: sql = "1 == 1"
        case let .simple(matcher): sql = matcher.sql
        case let .composite(this, and: and, or: or):
            sql = "(\(this.sql))"
            switch (and, or) {
            case (.some, .none): sql += " AND (\(and!.sql))"
            case (.none, .some): sql += " OR (\(or!.sql))"
            default: assert(false, "Bad Composite condition")
            }
        }
        if self.negated { sql = "NOT(\(sql))" }
        return sql
    }()
    
    @objc public func evaluate(on key: Any?) -> Bool {
        switch self.type {
        case .none: return !self.negated
        case let .simple(matcher): return matcher.evaluate(on: key) == !self.negated
        case let .composite(this, and: and, or: or):
            var boolVal = this.evaluate(on: key)
            switch (and, or) {
            case (.some, .none): boolVal = boolVal && and!.evaluate(on: key)
            case (.none, .some): boolVal = boolVal || or!.evaluate(on: key)
            default: assert(false, "Bad Composite condition")
            }
            return boolVal == !self.negated
        }
    }
    
    // NSCopying protocol
    
    private init(type: ConditionType, negated: Bool) {
        self.type = type
        self.negated = negated
        super.init()
    }
    
    @objc public func copy(with zone: NSZone? = nil) -> Any {
        return KBGenericCondition(type: self.type, negated: self.negated)
    }
    
    // NSSecureCodying protocol
    
    public static var supportsSecureCoding: Bool = true
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.negated, forKey: _KBGenericCondition_negated)
        aCoder.encode(self.type.stringValue, forKey: _KBGenericCondition_enumType)
        switch self.type {
        case .none: break
        case .simple(let matcher):
            aCoder.encode(matcher.comparison.rawValue, forKey: _KBGenericCondition_matcherType)
            aCoder.encode(matcher.value, forKey: _KBGenericCondition_matcherValue)
        case .composite(let this, and: let and, or: let or):
            aCoder.encode(this, forKey: _KBGenericCondition_this)
            aCoder.encode(and, forKey: _KBGenericCondition_and)
            aCoder.encode(or, forKey: _KBGenericCondition_or)
        }
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        let negated = aDecoder.decodeBool(forKey: _KBGenericCondition_negated)
        let enumType = aDecoder.decodeObject(of: NSString.self, forKey: _KBGenericCondition_enumType)! as String
        
        switch enumType {
        case "none":
            self.init(type: .none, negated: negated)
            return
        case "simple":
            let matcherType = aDecoder.decodeInteger(forKey: _KBGenericCondition_matcherType)
            let matcherValue = aDecoder.decodeObject(of: NSString.self, forKey: _KBGenericCondition_matcherValue)
            if let matchType = KBMatchType(rawValue: matcherType) {
                let matcher = Matcher(matchType, value: matcherValue! as String)
                self.init(type: .simple(matcher), negated: negated)
                return
            }
        case "composite":
            let this = aDecoder.decodeObject(of: KBGenericCondition.self, forKey: _KBGenericCondition_this)
            let and = aDecoder.decodeObject(of: KBGenericCondition.self, forKey: _KBGenericCondition_and)
            let or = aDecoder.decodeObject(of: KBGenericCondition.self, forKey: _KBGenericCondition_or)
            self.init(type: .composite(this!, and: and, or: or), negated: negated)
            return
        default:
            log.error("error decoding condition with enum type=\(enumType, privacy: .public)")
        }
        
        return nil
    }
}

/**
 KBTripleCondition
 Wrapper around KBGenericCondition to build "triple matchers".
 */
@objc(KBTripleCondition)
public class KBTripleCondition : NSObject, NSCopying, NSSecureCoding {
    
    public var rawCondition: KBGenericCondition
    
    @objc public override var description: String {
        return rawCondition.description
    }
    
    internal init(_ condition: KBGenericCondition) {
        self.rawCondition = condition
    }
    
    @objc public convenience init(value: Bool) {
        self.init(KBGenericCondition(value: value))
    }
    
    /**
     Convenience initializer for KBTripleCondition, instantiating a condition matching the subject, predicate, object passed as paramter.
     Initialize the underlying KBGenericCondition object to match values in the hexastore, starting from the triple components requested.
     
     - parameter subject: the subject value. Use nil as a wildcard
     - parameter predicate: the predicate value. Use nil as a wildcard
     - parameter object: the objecct value. Use nil as a wildcard
     */
    @objc public convenience init(subject: Label?, predicate: Label?, object: Label?) {
        let condition: KBGenericCondition
        
        switch (subject, predicate, object) {
            
        case (.some(let subject), .none, .none):
            let spoValue = KBHexastore.JOINER.combine(KBHexastore.SPO.rawValue, subject, end: true)
            let sopValue = KBHexastore.JOINER.combine(KBHexastore.SOP.rawValue, subject, end: true)
            
            let consecutive = KBGenericCondition(.beginsWith, value: spoValue)
                .or(KBGenericCondition(.beginsWith, value: sopValue))
            
            let psoCondition = KBGenericCondition(.beginsWith, value: KBHexastore.PSO.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.contains, value: KBHexastore.JOINER + subject + KBHexastore.JOINER))
            let posCondition = KBGenericCondition(.beginsWith, value: KBHexastore.POS.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER + subject))
            
            let ospCondition = KBGenericCondition(.beginsWith, value: KBHexastore.OSP.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.contains, value: KBHexastore.JOINER + subject + KBHexastore.JOINER))
            let opsCondition = KBGenericCondition(.beginsWith, value: KBHexastore.OPS.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER + subject))
            
            let separated = psoCondition.or(posCondition).or(ospCondition).or(opsCondition)
            
            condition = consecutive.or(separated)
            
        case (.none, .some(let predicate), .none):
            let psoValue = KBHexastore.JOINER.combine(KBHexastore.PSO.rawValue, predicate, end: true)
            let posValue = KBHexastore.JOINER.combine(KBHexastore.POS.rawValue, predicate, end: true)
            
            let consecutive = KBGenericCondition(.beginsWith, value: psoValue)
                .or(KBGenericCondition(.beginsWith, value: posValue))
            
            let spoCondition = KBGenericCondition(.beginsWith, value: KBHexastore.SPO.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.contains, value: KBHexastore.JOINER + predicate + KBHexastore.JOINER))
            let sopCondition = KBGenericCondition(.beginsWith, value: KBHexastore.SOP.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER + predicate))
            
            let opsCondition = KBGenericCondition(.beginsWith, value: KBHexastore.OPS.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.contains, value: KBHexastore.JOINER + predicate + KBHexastore.JOINER))
            let ospCondition = KBGenericCondition(.beginsWith, value: KBHexastore.OSP.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER + predicate))
            
            let separated = spoCondition.or(sopCondition).or(ospCondition).or(opsCondition)
            
            condition = consecutive.or(separated)
            
        case (.none, .none, .some(let object)):
            let ospValue = KBHexastore.JOINER.combine(KBHexastore.OSP.rawValue, object, end: true)
            let opsValue = KBHexastore.JOINER.combine(KBHexastore.OPS.rawValue, object, end: true)
            
            let consecutive = KBGenericCondition(.beginsWith, value: ospValue)
                .or(KBGenericCondition(.beginsWith, value: opsValue))
            
            let sopCondition = KBGenericCondition(.beginsWith, value: KBHexastore.SOP.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.contains, value: KBHexastore.JOINER + object + KBHexastore.JOINER))
            let spoCondition = KBGenericCondition(.beginsWith, value: KBHexastore.SPO.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER + object))
            
            let posCondition = KBGenericCondition(.beginsWith, value: KBHexastore.POS.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.contains, value: KBHexastore.JOINER + object + KBHexastore.JOINER))
            let psoCondition = KBGenericCondition(.beginsWith, value: KBHexastore.PSO.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER + object))
            
            let separated = sopCondition.or(spoCondition).or(posCondition).or(psoCondition)
            
            condition = consecutive.or(separated)
            
        case (.some(let subject), .some(let predicate), .none):
            let spoCondition = KBGenericCondition(.contains, value: KBHexastore.SPO.hexaValue(subject: subject,
                                                                                     predicate: predicate,
                                                                                     object: ""))
            let psoCondition = KBGenericCondition(.contains, value: KBHexastore.PSO.hexaValue(subject: subject,
                                                                                     predicate: predicate,
                                                                                     object: ""))
            let consecutive = spoCondition.or(psoCondition)
            
            let sopCondition = KBGenericCondition(.beginsWith, value: KBHexastore.JOINER.combine(KBHexastore.SOP.rawValue, subject, end: true))
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER + predicate))
            let posCondition = KBGenericCondition(.beginsWith, value: KBHexastore.JOINER.combine(KBHexastore.POS.rawValue, predicate, end: true))
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER + subject))
            
            let opsCondition = KBGenericCondition(.beginsWith, value: KBHexastore.OPS.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER.combine(predicate, subject, start: true)))
            let ospCondition = KBGenericCondition(.beginsWith, value: KBHexastore.OSP.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER.combine(subject, predicate, start: true)))
            
            let separated = sopCondition.or(posCondition).or(opsCondition).or(ospCondition)
            
            condition = consecutive.or(separated)
            
        case (.some(let subject), .none, .some(let object)):
            let sopCondition = KBGenericCondition(.contains, value: KBHexastore.SOP.hexaValue(subject: subject,
                                                                                              predicate: "",
                                                                                              object: object))
            let ospCondition = KBGenericCondition(.contains, value: KBHexastore.OSP.hexaValue(subject: subject,
                                                                                              predicate: "",
                                                                                              object: object))
            let consecutive = sopCondition.or(ospCondition)
            
            let spoCondition = KBGenericCondition(.beginsWith, value: KBHexastore.JOINER.combine(KBHexastore.SPO.rawValue, subject, end: true))
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER + object))
            let opsCondition = KBGenericCondition(.beginsWith, value: KBHexastore.JOINER.combine(KBHexastore.OPS.rawValue, object, end: true))
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER + subject))
            
            let psoCondition = KBGenericCondition(.beginsWith, value: KBHexastore.PSO.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER.combine(subject, object, start: true)))
            let posCondition = KBGenericCondition(.beginsWith, value: KBHexastore.POS.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER.combine(object, subject, start: true)))
            
            let separated = spoCondition.or(opsCondition).or(psoCondition).or(posCondition)
            
            condition = consecutive.or(separated)
            
        case (.none, .some(let predicate), .some(let object)):
            let posCondition = KBGenericCondition(.contains, value: KBHexastore.POS.hexaValue(subject: "",
                                                                                              predicate: predicate,
                                                                                              object: object))
            let opsCondition = KBGenericCondition(.contains, value: KBHexastore.OPS.hexaValue(subject: "",
                                                                                              predicate: predicate,
                                                                                              object: object))
            let consecutive = posCondition.or(opsCondition)
            
            let psoCondition = KBGenericCondition(.beginsWith, value: KBHexastore.JOINER.combine(KBHexastore.PSO.rawValue, predicate, end: true))
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER + object))
            let ospCondition = KBGenericCondition(.beginsWith, value: KBHexastore.JOINER.combine(KBHexastore.OSP.rawValue, object, end: true))
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER + predicate))
            
            let spoCondition = KBGenericCondition(.beginsWith, value: KBHexastore.SPO.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER.combine(predicate, object, start: true)))
            let sopCondition = KBGenericCondition(.beginsWith, value: KBHexastore.SOP.rawValue + KBHexastore.JOINER)
                .and(KBGenericCondition(.endsWith, value: KBHexastore.JOINER.combine(object, predicate, start: true)))
            
            let separated = psoCondition.or(ospCondition).or(spoCondition).or(sopCondition)
            
            condition = consecutive.or(separated)
            
        case (.some(let subject), .some(let predicate), .some(let object)):
            
            var c = KBGenericCondition(value: false)
            for hexatype in KBHexastore.allValues {
                c = c.or(KBGenericCondition(.equal, value: hexatype.hexaValue(subject: subject,
                                                                              predicate: predicate,
                                                                              object: object)))
            }
            condition = c
            
        default:
            condition = KBGenericCondition(value: true)
        }
        
        self.init(condition)
    }
    
    @objc public func and(_ condition: KBTripleCondition) -> KBTripleCondition {
        return KBTripleCondition(self.rawCondition.and(condition.rawCondition))
    }
    
    @objc public func or(_ condition: KBTripleCondition) -> KBTripleCondition {
        return KBTripleCondition(self.rawCondition.or(condition.rawCondition))
    }
    
    @objc public func evaluate(on key: AnyObject?) -> Bool {
        return self.rawCondition.evaluate(on: key)
    }
    
    // NSCopying protocol
    
    @objc public func copy(with zone: NSZone? = nil) -> Any {
        return KBTripleCondition(self.rawCondition)
    }
    
    // NSSecureCodying protocol
    
    public static var supportsSecureCoding: Bool = true
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.rawCondition, forKey: _KBTripleCondition_raw)
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        if let rawCondition = aDecoder.decodeObject(of: KBGenericCondition.self,
                                                    forKey: _KBTripleCondition_raw) {
            self.init(rawCondition)
        } else {
            return nil
        }
    }
}

/************************************************
 * SWIFT-PERF: Avoid using struct and copy-on-value
 * Use class and constraint protocol to class to avoid allocating too much space
 * This means that `func not` requires a new object to be allocated
 ************************************************/
public func not(_ condition: KBGenericCondition) -> KBGenericCondition {
    return KBGenericCondition(condition, negated: !condition.negated)
}

public func not(_ condition: KBTripleCondition) -> KBTripleCondition {
    return KBTripleCondition(not(condition.rawCondition))
}

extension KBTripleCondition {
    
    /**
     The KBTripleCondition to find all linked pairs (subject, object)
     
     The label on the connection needs to match the one passed as argument
     
     - parameter label: constraints the search to a specific predicate label
     - parameter matchType: (defaults .Equal) defines the match type
     on the predicate label
     
     - returns: The condition
     */
    @objc public class func havingPredicate(_ label: Label,
                                          matchType: KBMatchType = .equal) throws -> KBTripleCondition {
        let partial: String
        
        switch matchType {
        case .equal:
            partial = KBHexastore.JOINER.combine(
                KBHexastore.PSO.rawValue,
                label,
                end: true
            )
        case .beginsWith:
            partial = KBHexastore.JOINER.combine(
                KBHexastore.PSO.rawValue,
                label,
                end: false
            )
        default:
            throw KBError.notSupported
        }
        
        return KBTripleCondition(KBGenericCondition(.beginsWith, value: partial))
    }
    
    /**
     The KBTripleCondition to find all predicate labels connecting the two KBEntity objects passed as input
     
     - parameter subject: The source entity
     - parameter object: The target entity
     
     - returns: The condition
     */
    
    @objc public class func havingSubject(_ subject: KBEntity,
                                        andAbject object: KBEntity) -> KBTripleCondition {
        let partial = KBHexastore.JOINER.combine(
            KBHexastore.SOP.rawValue,
            subject.identifier,
            object.identifier
        )
        return KBTripleCondition(KBGenericCondition(.beginsWith, value: partial))
    }
    
    internal class func forRules(from subject: KBEntity) -> KBTripleCondition {
        return KBTripleCondition(
            subject: subject.identifier,
            predicate: nil,
            object: /* TODO: beginsWith: RULE_PREFIX*/ nil
        )
    }
}
