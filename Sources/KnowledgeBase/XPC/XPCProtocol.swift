//
//  XPCProtocol.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/27/21.
//

import Foundation

@objc(KBStorageXPCProtocol)
public protocol KBStorageXPCProtocol {
    
    // SELECT
    
    func keys(inStoreWithIdentifier identifier: String, completionHandler: @escaping (Error?, [String]?) -> ())
    
    func keys(matching: KBGenericCondition, inStoreWithIdentifier identifier: String, completionHandler: @escaping (Error?, [String]?) -> ())
    
    func value(forKey: String, inStoreWithIdentifier identifier: String, completionHandler: @escaping (Error?, Any?) -> ())
    
    func keysAndValues(inStoreWithIdentifier identifier: String, completionHandler: @escaping (Error?, KBKVPairs?) -> ())
    
    func keysAndValues(forKeysMatching: KBGenericCondition, inStoreWithIdentifier identifier: String, completionHandler: @escaping (Error?, KBKVPairs?) -> ())
    
    func keyValuesAndTimestamps(
        forKeysMatching: KBGenericCondition,
        inStoreWithIdentifier identifier: String,
        paginate: KBPaginationOptions?,
        sort: KBSortDirection.RawValue?,
        completionHandler: @escaping (Error?, [KBKVObjcPairWithTimestamp]?) -> ()
    )
    
    func keysAndValues(
        createdWithin interval: DateInterval,
        paginate: KBPaginationOptions?,
        sort: KBSortDirection.RawValue,
        inStoreWithIdentifier identifier: String,
        completionHandler: @escaping (Error?, [Date: KBKVPairs]?) -> ()
    )
    
    func tripleComponents(matching: KBTripleCondition?, inStoreWithIdentifier identifier: String, completionHandler: @escaping (Error?, [KBTriple]?) -> ())

    // CREATE/UPDATE
    
    func save(_: [String: Any], toStoreWithIdentifier: String, completionHandler: @escaping KBObjCActionCompletion)
    
    func save(_: [String: Any], toSynchedStoreWithIdentifier: String, completionHandler: @escaping KBObjCActionCompletion)

    // DELETE
    
    func removeValues(forKeys: [String], fromStoreWithIdentifier: String, completionHandler: @escaping KBObjCActionCompletion)
    
    func removeValues(forKeys: [String], fromSynchedStoreWithIdentifier: String, completionHandler: @escaping KBObjCActionCompletion)
    
    func removeValues(forKeysMatching: KBGenericCondition, fromStoreWithIdentifier: String, completionHandler: @escaping (Error?, [String]?) -> ())
    
    func removeValues(forKeysMatching: KBGenericCondition, fromSynchedStoreWithIdentifier: String, completionHandler: @escaping (Error?, [String]?) -> ())
    
    func removeAll(fromStoreWithIdentifier: String, completionHandler: @escaping (Error?, [String]?) -> ())
    
    func removeAll(fromSynchedStoreWithIdentifier: String, completionHandler: @escaping (Error?, [String]?) -> ())

    // LINKS
    
    func setWeight(forLinkWithLabel: Label, between: Label, and: Label, toValue: Int, inStoreWithIdentifier: String, completionHandler: @escaping KBObjCActionCompletion)
    
    func increaseWeight(forLinkWithLabel: Label, between: Label, and: Label, inStoreWithIdentifier: String, completionHandler: @escaping (Error?, Int) -> ())
    
    func decreaseWeight(forLinkWithLabel: Label, between: Label, and: Label, inStoreWithIdentifier: String, completionHandler: @escaping (Error?, Int) -> ())
    
    func dropLink(withLabel: Label, between: Label, and: Label, inStoreWithIdentifier: String, completionHandler: @escaping KBObjCActionCompletion)
    
    func dropLinks(withLabel: Label, from: Label, inStoreWithIdentifier: String, completionHandler: @escaping KBObjCActionCompletion)
    
    func dropLinks(withLabel: Label, to: Label, inStoreWithIdentifier: String, completionHandler: @escaping KBObjCActionCompletion)
    
    func dropLinks(between: Label, and: Label, inStoreWithIdentifier: String, completionHandler: @escaping KBObjCActionCompletion)
    
    func dropLinks(fromAndTo: Label, inStoreWithIdentifier: String, completionHandler: @escaping KBObjCActionCompletion)

    // CLOUD SYNC

    func disableSyncAndDeleteCloudData(completionHandler: @escaping KBObjCActionCompletion)
}
