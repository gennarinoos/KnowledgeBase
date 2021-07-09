//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/27/21.
//

import Foundation

@objc(KBStorageXPCInterface) protocol KBStorageXPCInterface {
    
    // SELECT
    
    func keys(inStoreWithIdentifier identifier: String) async throws -> [String]
    
    func keys(matching: KBGenericCondition, inStoreWithIdentifier identifier: String) async throws -> [String]
    
    func value(forKey: String, inStoreWithIdentifier identifier: String) async throws -> Any?
    
    func keysAndValues(inStoreWithIdentifier identifier: String) async throws -> [String: Any]
    
    func keysAndValues(forKeysMatching: KBGenericCondition, inStoreWithIdentifier identifier: String) async throws  -> [String: Any]
    
    func tripleComponents(matching: KBTripleCondition?, inStoreWithIdentifier identifier: String) async throws -> [KBTriple]

    // CREATE/UPDATE
    
    func save(_: [String: Any], toStoreWithIdentifier: String) async throws
    
    func save(_: [String: Any], toSynchedStoreWithIdentifier: String) async throws

    // DELETE
    
    func removeValue(forKey: String, fromStoreWithIdentifier: String) async throws
    
    func removeValue(forKey: String, fromSynchedStoreWithIdentifier: String) async throws
    
    func removeValues(forKeys: [String], fromStoreWithIdentifier: String) async throws
    
    func removeValues(forKeys: [String], fromSynchedStoreWithIdentifier: String) async throws
    
    func removeValues(matching: KBGenericCondition, fromStoreWithIdentifier: String) async throws
    
    func removeValues(matching: KBGenericCondition, fromSynchedStoreWithIdentifier: String) async throws
    
    func removeAllValues(fromStoreWithIdentifier: String) async throws
    
    func removeAllValues(fromSynchedStoreWithIdentifier: String) async throws

    // LINKS
    
    func setWeight(forLinkWithLabel: String, between: String, and: String, toValue: Int, inStoreWithIdentifier: String) async throws
    
    func increaseWeight(forLinkWithLabel: String, between: String, and: String, inStoreWithIdentifier: String) async throws -> Int
    
    func decreaseWeight(forLinkWithLabel: String, between: String, and: String, inStoreWithIdentifier: String) async throws -> Int
    
    func dropLink(withLabel: String, between: String, and: String, inStoreWithIdentifier: String) async throws
    
    func dropLinks(withLabel: String?, from: String, inStoreWithIdentifier: String) async throws
    
    func dropLinks(between: String, and: String, inStoreWithIdentifier: String) async throws

    // CLOUD SYNC

    func disableSyncAndDeleteCloudData() async throws
}
