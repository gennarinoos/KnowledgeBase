import Foundation


class KBCloudKitSQLBackingStore: KBSQLBackingStore {
    
    override var name: String {
        get { return KnowledgeBaseSQLSynchedIdentifier }
        set(v) {}
    }
    
    class override func mainInstance() -> Self? {
        return self.init(name: KnowledgeBaseSQLSynchedIdentifier)
    }
    
    // MARK: SELECT
    
    func triplesComponents(
        matching condition: KBTripleCondition?
    ) async throws -> [KBTriple] {
        log.fault("\(KnowledgeBaseBundleIdentifier, privacy: .public) store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func verify(path: KBPath) async throws -> Bool {
        log.fault("\(KnowledgeBaseBundleIdentifier, privacy: .public) store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    //MARK: INSERT
    
    override func writeBatch() -> KBKVStoreWriteBatch {
        return KBCloudKitSQLWriteBatch(backingStore: self)
    }
    
    func setWeight(
        forLinkWithLabel predicate: String,
        between subjectIdentifier: String,
        and objectIdentifier: String,
        toValue newValue: Int
    ) async throws {
        log.fault("\(KnowledgeBaseBundleIdentifier, privacy: .public) store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func increaseWeight(
        forLinkWithLabel predicate: String, 
        between subjectIdentifier: String,
        and objectIdentifier: String
    ) async throws -> Int {
        log.fault("\(KnowledgeBaseBundleIdentifier, privacy: .public) store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func decreaseWeight(
        forLinkWithLabel predicate: Label,
        between subjectIdentifier: Label,
        and objectIdentifier: Label
    ) async throws -> Int {
        log.fault("\(KnowledgeBaseBundleIdentifier, privacy: .public) store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    //MARK: DELETE
    
    func dropLink(withLabel predicate: Label, between subjectIdentifier: Label, and objectIdentifier: Label) async throws {
        log.fault("\(KnowledgeBaseBundleIdentifier, privacy: .public) store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func dropLinks(withLabel predicate: Label, from subjectIdentifier: Label) async throws {
        log.fault("\(KnowledgeBaseBundleIdentifier, privacy: .public) store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func dropLinks(withLabel predicate: Label, to objectIdentifier: Label) async throws {
        log.fault("\(KnowledgeBaseBundleIdentifier, privacy: .public) store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func dropLinks(between subjectIdentifier: Label, and objectIdentifier: Label) async throws {
        log.fault("\(KnowledgeBaseBundleIdentifier, privacy: .public) store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func dropLinks(fromAndTo entityIdentifier: Label) async throws {
        log.fault("\(KnowledgeBaseBundleIdentifier, privacy: .public) store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func disableSyncAndDeleteCloudData() async throws {
        // TODO: Implement
    }
}
