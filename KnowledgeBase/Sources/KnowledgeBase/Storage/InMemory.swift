//
//  InMemory.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/22/21.
//

import Foundation


class KBInMemoryBackingStore : KBSQLBackingStoreProtocol {
    var name: String {
        get { return KnowledgeBaseInMemoryIdentifier }
        set(v) {}
    }
    
    // In-memory SQL database
    var storeHandler: KBPersistentStoreHandler {
        get {
            return KBPersistentStoreHandler.inMemoryHandler()!
        }
    }
    
    func writeBatch() -> KBKnowledgeStoreWriteBatch {
        return KBSQLWriteBatch(backingStore: self)
    }
}
