extension KBGenericCondition {
    
    static func fullTripleHexaCondition(subject: Label, predicate: Label, object: Label) -> KBGenericCondition {
        var condition = KBGenericCondition(value: false)
        for hexatype in KBHexastore.allValues {
            condition = condition.or(KBGenericCondition(.equal, value: hexatype.hexaValue(
                subject: subject,
                predicate: predicate,
                object: object
            )))
        }
        return condition
    }
    
    static func partialTripleHexaCondition(entityIdentifier identifier: Label) -> KBGenericCondition {
        var condition = KBGenericCondition(value: false)
        
        condition = condition.or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.JOINER.combine(
                    KBHexastore.SPO.rawValue,
                    identifier,
                    end: true
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.JOINER.combine(
                    KBHexastore.SOP.rawValue,
                    identifier,
                    end: true
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.JOINER.combine(
                    KBHexastore.OSP.rawValue,
                    identifier,
                    end: true
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.JOINER.combine(
                    KBHexastore.OPS.rawValue,
                    identifier,
                    end: true
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.PSO.rawValue + KBHexastore.JOINER
            )
            .and(
                KBGenericCondition(
                    .endsWith,
                    value: KBHexastore.JOINER + identifier
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.POS.rawValue + KBHexastore.JOINER
            )
            .and(
                KBGenericCondition(
                    .endsWith,
                    value: KBHexastore.JOINER + identifier
                )
            )
        )
        
        return condition
    }
    
    static func partialTripleHexaCondition(subject: Label, predicate: Label) -> KBGenericCondition {
        var condition = KBGenericCondition(value: false)
        
        condition = condition.or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.JOINER.combine(
                    KBHexastore.SPO.rawValue,
                    subject,
                    predicate,
                    end: true
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.JOINER.combine(
                    KBHexastore.SOP.rawValue,
                    subject,
                    end: true
                )
            )
            .and(
                KBGenericCondition(.endsWith, value: KBHexastore.JOINER + predicate)
            )
        ).or(
            KBGenericCondition(
                .beginsWith, value: KBHexastore.OSP.rawValue + KBHexastore.JOINER
            )
            .and(
                KBGenericCondition(
                    .endsWith,
                    value: KBHexastore.JOINER.combine(
                        subject,
                        predicate,
                        start: true
                    )
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith, value: KBHexastore.OPS.rawValue + KBHexastore.JOINER
            )
            .and(
                KBGenericCondition(
                    .endsWith,
                    value: KBHexastore.JOINER.combine(
                        predicate,
                        subject,
                        start: true
                    )
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.PSO.rawValue + KBHexastore.JOINER
            )
            .and(
                KBGenericCondition(
                    .endsWith,
                    value: KBHexastore.JOINER.combine(
                        subject,
                        predicate,
                        start: true
                    )
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.JOINER.combine(
                    KBHexastore.POS.rawValue,
                    predicate,
                    end: true
                )
            )
            .and(
                KBGenericCondition(
                    .endsWith,
                    value: KBHexastore.JOINER + subject
                )
            )
        )
        
        return condition
    }
    
    static func partialTripleHexaCondition(predicate: Label, object: Label) -> KBGenericCondition {
        var condition = KBGenericCondition(value: false)
        
        condition = condition.or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.JOINER.combine(
                    KBHexastore.OPS.rawValue,
                    object,
                    predicate,
                    end: true
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.JOINER.combine(
                    KBHexastore.OSP.rawValue,
                    object,
                    end: true
                )
            )
            .and(
                KBGenericCondition(.endsWith, value: KBHexastore.JOINER + predicate)
            )
        ).or(
            KBGenericCondition(
                .beginsWith, value: KBHexastore.SOP.rawValue + KBHexastore.JOINER
            )
            .and(
                KBGenericCondition(
                    .endsWith,
                    value: KBHexastore.JOINER.combine(
                        object,
                        predicate,
                        start: true
                    )
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith, value: KBHexastore.SPO.rawValue + KBHexastore.JOINER
            )
            .and(
                KBGenericCondition(
                    .endsWith,
                    value: KBHexastore.JOINER.combine(
                        predicate,
                        object,
                        start: true
                    )
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.JOINER.combine(
                    KBHexastore.PSO.rawValue,
                    predicate,
                    end: true
                )
            )
            .and(
                KBGenericCondition(
                    .endsWith,
                    value: KBHexastore.JOINER + object
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.JOINER.combine(
                    KBHexastore.POS.rawValue,
                    predicate,
                    object,
                    end: true
                )
            )
        )
        
        return condition
    }
    
    static func partialTripleHexaCondition(subject: Label, object: Label) -> KBGenericCondition {
        var condition = KBGenericCondition(value: false)
        
        condition = condition.or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.JOINER.combine(
                    KBHexastore.OSP.rawValue,
                    object,
                    subject,
                    end: true
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.JOINER.combine(
                    KBHexastore.OPS.rawValue,
                    object,
                    end: true
                )
            )
            .and(
                KBGenericCondition(.endsWith, value: KBHexastore.JOINER + subject)
            )
        ).or(
            KBGenericCondition(
                .beginsWith, value: KBHexastore.POS.rawValue + KBHexastore.JOINER
            )
            .and(
                KBGenericCondition(
                    .endsWith,
                    value: KBHexastore.JOINER.combine(
                        object,
                        subject,
                        start: true
                    )
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith, value: KBHexastore.PSO.rawValue + KBHexastore.JOINER
            )
            .and(
                KBGenericCondition(
                    .endsWith,
                    value: KBHexastore.JOINER.combine(
                        subject,
                        object,
                        start: true
                    )
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.JOINER.combine(
                    KBHexastore.SPO.rawValue,
                    subject,
                    end: true
                )
            )
            .and(
                KBGenericCondition(
                    .endsWith,
                    value: KBHexastore.JOINER + object
                )
            )
        ).or(
            KBGenericCondition(
                .beginsWith,
                value: KBHexastore.JOINER.combine(
                    KBHexastore.SOP.rawValue,
                    subject,
                    object,
                    end: true
                )
            )
        )
        
        return condition
    }
}
