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
    
    func keys(
        inStoreWithIdentifier identifier: String
    ) async throws -> [String]
    
    func keys(
        matching: KBGenericCondition,
        inStoreWithIdentifier identifier: String
    ) async throws -> [String]
    
    func value(
        forKey: String,
        inStoreWithIdentifier identifier: String
    ) async throws -> Any?
    
    func keysAndValues(
        inStoreWithIdentifier identifier: String
    ) async throws -> KBKVPairs
    
    func keysAndValues(
        forKeysMatching: KBGenericCondition,
        inStoreWithIdentifier identifier: String
    ) async throws -> KBKVPairs
    
    func keyValuesAndTimestamps(
        forKeysMatching: KBGenericCondition,
        timestampMatching timeCondition: KBTimestampCondition?,
        inStoreWithIdentifier identifier: String,
        paginate: KBPaginationOptions?,
        sort: KBSortDirection.RawValue?
    ) async throws -> [KBKVObjcPairWithTimestamp]
    
    func keysAndValues(
        createdWithin interval: DateInterval,
        paginate: KBPaginationOptions?,
        sort: KBSortDirection.RawValue,
        inStoreWithIdentifier identifier: String
    ) async throws -> [Date: KBKVPairs]
    
    func tripleComponents(
        matching: KBTripleCondition?,
        inStoreWithIdentifier identifier: String
    ) async throws -> [KBTriple]

    // CREATE/UPDATE
    
    func save(
        _: [String: Any],
        toStoreWithIdentifier: String
    ) async throws
    
    func save(
        _: [String: Any],
        toSynchedStoreWithIdentifier: String
    ) async throws

    // DELETE
    
    func removeValues(
        forKeys: [String],
        fromStoreWithIdentifier: String
    ) async throws
    
    func removeValues(
        forKeys: [String], 
        fromSynchedStoreWithIdentifier: String
    ) async throws
    
    func removeValues(
        forKeysMatching: KBGenericCondition,
        fromStoreWithIdentifier: String
    ) async throws -> [String]
    
    func removeValues(forKeysMatching: KBGenericCondition, fromSynchedStoreWithIdentifier: String
    ) async throws -> [String]
    
    func removeAll(
        fromStoreWithIdentifier: String
    ) async throws -> [String]
    
    func removeAll(
        fromSynchedStoreWithIdentifier: String
    ) async throws -> [String]

    // LINKS
    
    func setWeight(
        forLinkWithLabel: Label,
        between: Label,
        and: Label,
        toValue: Int,
        inStoreWithIdentifier: String
    ) async throws
    
    func increaseWeight(
        forLinkWithLabel: Label,
        between: Label,
        and: Label,
        inStoreWithIdentifier: String
    ) async throws -> Int
    
    func decreaseWeight(
        forLinkWithLabel: Label,
        between: Label,
        and: Label,
        inStoreWithIdentifier: String
    ) async throws -> Int
    
    func dropLink(
        withLabel: Label,
        between: Label,
        and: Label,
        inStoreWithIdentifier: String
    ) async throws
    
    func dropLinks(
        withLabel: Label,
        from: Label,
        inStoreWithIdentifier: String
    ) async throws
    
    func dropLinks(
        withLabel: Label,
        to: Label,
        inStoreWithIdentifier: String
    ) async throws
    
    func dropLinks(
        between: Label,
        and: Label,
        inStoreWithIdentifier: String
    ) async throws
    
    func dropLinks(
        fromAndTo: Label, 
        inStoreWithIdentifier: String
    ) async throws

    // CLOUD SYNC

    func disableSyncAndDeleteCloudData() async throws
}
