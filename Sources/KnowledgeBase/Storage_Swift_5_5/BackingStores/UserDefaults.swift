import Foundation

class KBUserDefaultsBackingStore : KBBackingStore {
    
    private var kv: UserDefaults
    var name: String {
        get { return KnowledgeBaseUserDefaultsIdentifier }
        set(v) {}
    }

    init() {
        log.trace("initializing .UserDefaults Store with suite name \(KnowledgeBaseBundleIdentifier, privacy: .public)")

        if let defaults = UserDefaults(suiteName: KnowledgeBaseBundleIdentifier) {
            self.kv = defaults
        } else {
            log.fault("Can't initialize defaults with suiteName \(KnowledgeBaseBundleIdentifier, privacy: .public). Using standard user defaults")
            self.kv = UserDefaults()
        }
    }

    internal func synchronize() {
        self.kv.synchronize()
    }
    
    func writeBatch() -> KBKVStoreWriteBatch {
        return KBUserDefaultsWriteBatch(backingStore: self)
    }

    //MARK: SELECT

    func keys() async throws -> [String] {
        ((self.kv.dictionaryRepresentation() as NSDictionary).allKeys as! [String])
    }
    
    func keys(matching condition: KBGenericCondition) async throws -> [String] {
        let filteredKeys = ((self.kv.dictionaryRepresentation() as NSDictionary).allKeys.filter {
            k -> Bool in
            return condition.evaluate(on: k)
        })
        return filteredKeys as! [String]
    }
    
    internal func value(for key: String) async throws -> Any? {
        self.kv.object(forKey: key)
    }
    
    func values() async throws -> [Any] {
        return (self.kv.dictionaryRepresentation() as NSDictionary).allValues
    }
    
    func values(for keys: [String]) async throws -> [Any?] {
        return keys.map { key in self.kv.object(forKey: key) }
    }
    
    func values(forKeysMatching condition: KBGenericCondition) async throws -> [Any?] {
        let allKeys = try await self.keys()
        let filteredKeys = allKeys.filter { condition.evaluate(on: $0) }
        return filteredKeys.map { key in self.kv.object(forKey: key) }
    }
    
    func keyValuesAndTimestamps(
        forKeysMatching condition: KBGenericCondition,
        timestampMatching timeCondition: KBTimestampCondition?,
        paginate: KBPaginationOptions?,
        sort: KBSortDirection?
    ) async throws -> [KBKVPairWithTimestamp] {
        guard paginate == nil, sort == nil else {
            throw KBError.notSupported
        }
        
        let allKeys = try await self.keys()
        let filteredKeys = allKeys.filter { condition.evaluate(on: $0) }
        return filteredKeys.map { key in
            KBKVPairWithTimestamp(
                key: key,
                value: self.kv.object(forKey: key),
                timestamp: Date()
            )
        }
    }
    
    func dictionaryRepresentation() async throws -> KBKVPairs {
        self.kv.dictionaryRepresentation()
    }
    
    func dictionaryRepresentation(
        forKeysMatching condition: KBGenericCondition
    ) async throws -> KBKVPairs {
        let allKeys = try await self.keys()
        return allKeys.reduce(KBKVPairs(), {
            (dict, k) in
            if condition.evaluate(on: k) {
                var newDict = dict
                newDict[k] = self.kv.object(forKey: k)!
                return newDict
            }
            return dict
        })
    }
    
    func dictionaryRepresentation(
        createdWithin interval: DateInterval,
        paginate: KBPaginationOptions?,
        sort: KBSortDirection
    ) async throws -> [Date: KBKVPairs] {
        log.fault(".UserDefaults store does not support timestamps")
        throw KBError.notSupported
    }
    
    func triplesComponents(
        matching condition: KBTripleCondition?
    ) async throws -> [KBTriple] {
        log.fault(".UserDefaults store is not meant to store triples")
        throw KBError.notSupported
    }
    
    func set(value: Any?, for key: String) async throws {
        self.kv.set(value, forKey: key)
    }
        
    func removeValue(for key: String) async throws {
        self.kv.removeObject(forKey: key)
        self.synchronize()
    }
    
    func removeValues(for keys: [String]) async throws {
        for key in keys {
            self.kv.removeObject(forKey: key)
        }
        self.synchronize()
    }
    
    func removeValues(
        forKeysMatching condition: KBGenericCondition
    ) async throws -> [String] {
        let allKeys = try await self.keys()
        var removedKeys = [String]()
        for key in allKeys {
            if condition.evaluate(on: key) {
                self.kv.removeObject(forKey: key)
                removedKeys.append(key)
            }
        }
        self.synchronize()
        return removedKeys
    }
    
    func removeAll() async throws -> [String] {
        let allKeys = try await self.keys()
        var removedKeys = [String]()
        for key in allKeys {
            self.kv.removeObject(forKey: key)
            removedKeys.append(key)
        }
        self.synchronize()
        return removedKeys
    }
    
    // GRAPH LINKS
    func verify(path: KBPath) async throws -> Bool {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func setWeight(
        forLinkWithLabel predicate: String,
        between subjectIdentifier: String,
        and objectIdentifier: String,
        toValue newValue: Int
    ) async throws {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func increaseWeight(
        forLinkWithLabel predicate: String,
        between subjectIdentifier: String,
        and objectIdentifier: String
    ) async throws -> Int {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func decreaseWeight(
        forLinkWithLabel predicate: Label,
        between subjectIdentifier: Label,
        and objectIdentifier: Label
    ) async throws -> Int {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func dropLink(
        withLabel predicate: Label,
        between subjectIdentifier: Label,
        and objectIdentifier: Label
    ) async throws {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func dropLinks(
        withLabel predicate: Label,
        from subjectIdentifier: Label
    ) async throws {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func dropLinks(
        withLabel predicate: Label,
        to objectIdentifier: Label
    ) async throws {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func dropLinks(
        between subjectIdentifier: Label,
        and objectIdentifier: Label
    ) async throws {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    func dropLinks(fromAndTo entityIdentifier: Label) async throws {
        log.fault(".UserDefaults store is not meant to store graphs")
        throw KBError.notSupported
    }
    
    // CLOUD SYNC
    func disableSyncAndDeleteCloudData() async throws {
        log.fault(".UserDefaults store does not support cloud syncing")
        throw KBError.notSupported
    }
    
}
