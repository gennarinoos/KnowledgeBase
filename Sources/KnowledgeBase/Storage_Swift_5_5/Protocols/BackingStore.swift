//
//  BackingStore.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/15/21.
//

import Foundation

protocol KBBackingStoreProtocol {
    
    // MARK: KVStore
    func keys() async throws -> [String]
    
    func keys(matching: KBGenericCondition) async throws -> [String]
    
    func value(for key: String) async throws -> Any?
    
    func values() async throws -> [Any]
    
    func values(for keys: [String]) async throws -> [Any?]
    
    func values(
        forKeysMatching: KBGenericCondition
    ) async throws -> [Any?]
    
    func keyValuesAndTimestamps(
        forKeysMatching: KBGenericCondition,
        timestampMatching timeCondition: KBTimestampCondition?,
        paginate: KBPaginationOptions?,
        sort: KBSortDirection?
    ) async throws -> [KBKVPairWithTimestamp]
    
    func dictionaryRepresentation() async throws -> KBKVPairs
    
    func dictionaryRepresentation(
        forKeysMatching: KBGenericCondition
    ) async throws -> KBKVPairs
    
    func dictionaryRepresentation(
        createdWithin: DateInterval,
        paginate: KBPaginationOptions?,
        sort: KBSortDirection
    ) async throws -> [Date: KBKVPairs]
    
    func set(value: Any?, for key: String) async throws
    
    func removeValue(for key: String) async throws
    
    func removeValues(for keys: [String]) async throws
    
    func removeValues(forKeysMatching condition: KBGenericCondition) async throws -> [String]
    
    func removeAll() async throws -> [String]
    
    // MARK: KnowledgeStore

    func triplesComponents(
        matching condition: KBTripleCondition?
    ) async throws -> [KBTriple]
    
    func verify(path: KBPath) async throws -> Bool
    
    func setWeight(
        forLinkWithLabel predicate: String,
        between subjectIdentifier: String,
        and objectIdentifier: String,
        toValue newValue: Int
    ) async throws
    
    func increaseWeight(
        forLinkWithLabel predicate: String,
        between subjectIdentifier: String,
        and objectIdentifier: String
    ) async throws -> Int
    
    func decreaseWeight(
        forLinkWithLabel predicate: Label,
        between subjectIdentifier: Label,
        and objectIdentifier: Label
    ) async throws -> Int
    
    func dropLink(
        withLabel predicate: Label,
        between subjectIdentifier: Label,
        and objectIdentifier: Label
    ) async throws
    
    func dropLinks(
        withLabel predicate: Label,
        from subjectIdentifier: Label
    ) async throws
    
    func dropLinks(
        withLabel predicate: Label,
        to objectIdentifier: Label
    ) async throws
    
    func dropLinks(
        between subjectIdentifier: Label,
        and objectIdentifier: Label
    ) async throws
    
    func dropLinks(fromAndTo entityIdentifier: Label) async throws
    
    // MARK: Cloud sync
    func disableSyncAndDeleteCloudData() async throws
}

/**
 Protocol that every backend needs to implement
 */
protocol KBBackingStore: KBBackingStoreProtocol {
    var name: String { get }
    func writeBatch() -> KBKVStoreWriteBatch
}

/**
 BackingStore using a SQL persistent storage handler.
 */
protocol KBPersistentBackingStore: KBBackingStore {
    var sqlHandler: KBSQLHandler { get }
}
