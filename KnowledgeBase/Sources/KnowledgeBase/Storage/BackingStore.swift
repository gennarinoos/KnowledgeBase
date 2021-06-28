//
//  BackingStore.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/19/21.
//

import Foundation

/// Protocol that every backend needs to implement
protocol KBBackingStore {
   
   var name: String { get }
   func writeBatch() -> KBKnowledgeStoreWriteBatch
    
    // KVS SELECT
    func keys() async throws -> [String]
    func keys(matching: KBGenericCondition) async throws -> [String]
    
    func _value(forKey key: String) async throws -> Any?
    
    func values() async throws -> [Any]
    func values(forKeys keys: [String]) async throws -> [Any?]
    func values(forKeysMatching: KBGenericCondition) async throws -> [Any]
    
    func dictionaryRepresentation() async throws -> KBJSONObject
    func dictionaryRepresentation(forKeysMatching: KBGenericCondition) async throws -> KBJSONObject
    
    func triplesComponents(matching condition: KBTripleCondition?) async throws -> [KBTriple]
    
    // KVS INSERT
    func setValue(_: Any?, forKey: String) async throws
    
    // KVS DELETE
    func removeValue(forKey key: String) async throws
    func removeValues(forKeys keys: [String]) async throws
    func removeValues(matching condition: KBGenericCondition) async throws
    func removeAllValues() async throws
   
   // GRAPH LINKS
    func verify(path: KBPath) async throws -> Bool
    
   func setWeight(forLinkWithLabel predicate: String,
                  between subjectIdentifier: String,
                  and objectIdentifier: String,
                  toValue newValue: Int) async throws
   func increaseWeight(forLinkWithLabel predicate: String,
                       between subjectIdentifier: String,
                       and objectIdentifier: String) async throws -> Int
   func decreaseWeight(forLinkWithLabel predicate: Label,
                       between subjectIdentifier: Label,
                       and objectIdentifier: Label) async throws -> Int
   func dropLink(withLabel predicate: String,
                 between subjectIdentifier: String,
                 and objectIdentifier: String) async throws
   func dropLinks(withLabel predicate: String?,
                  from subjectIdentifier: String) async throws
   func dropLinks(between subjectIdentifier: String,
                  and objectIdentifier: String) async throws
   
   func disableSyncAndDeleteCloudData() async throws
}

protocol KBPersistentBackingStore: KBBackingStore {
    var storeHandler: KBPersistentStoreHandler { get }
}
