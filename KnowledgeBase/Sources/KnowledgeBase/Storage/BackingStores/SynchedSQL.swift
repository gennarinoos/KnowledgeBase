//
//  SynchedSQLXPC.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/28/21.
//

import Foundation

class KBCloudKitSQLBackingStore : KBSQLBackingStore {
    
    override var name: String {
        get { return KnowledgeBaseSQLSynchedIdentifier }
        set(v) {}
    }
    
    class override func mainInstance() -> Self {
        return self.init(name: KnowledgeBaseSQLSynchedIdentifier)
    }
    
    // MARK: SELECT
    
    func triplesComponents(matching condition: KBTripleCondition?) async throws -> [KBTriple] {
        log.fault("%@ store is not meant to store triples", KnowledgeBaseSQLSynchedIdentifier)
        throw KBError.notSupported
    }
    
    func verify(path: KBPath) async throws -> Bool {
        log.fault("%@ store is not meant to store graphs", KnowledgeBaseSQLSynchedIdentifier)
        throw KBError.notSupported
    }
    
    //MARK: INSERT
    
    override func writeBatch() -> KBKVStoreWriteBatch {
        return KBCloudKitSQLWriteBatch(backingStore: self)
    }
    
    func increaseWeight(forLinkWithLabel predicate: Label,
                        between subjectIdentifier: Label,
                        and objectIdentifier: Label) async throws -> Int {
        log.fault("%@ store is not meant to store graphs", KnowledgeBaseSQLSynchedIdentifier)
        throw KBError.notSupported
    }
    
    func decreaseWeight(forLinkWithLabel predicate: Label,
                        between subjectIdentifier: Label,
                        and objectIdentifier: Label) async throws -> Int {
        log.fault("%@ store is not meant to store graphs", KnowledgeBaseSQLSynchedIdentifier)
        throw KBError.notSupported
    }
    
    func setWeight(forLinkWithLabel predicate: Label,
                   between subjectIdentifier: Label,
                   and objectIdentifier: Label,
                   toValue newValue: Int) async throws {
        log.fault("%@ store is not meant to store graphs", KnowledgeBaseSQLSynchedIdentifier)
        throw KBError.notSupported
    }
    
    //MARK: DELETE

    func dropLink(withLabel predicate: Label,
                  between subjectIdentifier: Label,
                  and objectIdentifier: Label) async throws {
        log.fault("%@ store is not meant to store graphs", KnowledgeBaseSQLSynchedIdentifier)
        throw KBError.notSupported
    }
    
    func dropLinks(withLabel predicate: Label?,
                   from subjectIdentifier: Label) async throws {
        log.fault("%@ store is not meant to store graphs", KnowledgeBaseSQLSynchedIdentifier)
        throw KBError.notSupported
    }
    
    func dropLinks(between subjectIdentifier: Label,
                   and objectIdentifier: Label) async throws {
        log.fault("%@ store is not meant to store graphs", KnowledgeBaseSQLSynchedIdentifier)
        throw KBError.notSupported
    }
    
    func disableSyncAndDeleteCloudData() async throws {
        // TODO: Disable sync and delete cloud data
    }
}
