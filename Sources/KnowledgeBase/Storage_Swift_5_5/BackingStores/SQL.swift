import Foundation

public var DatabaseExtension = "db"

protocol KBSQLBackingStoreProtocol : KBPersistentBackingStore {
}

extension KBSQLBackingStoreProtocol {
    
    func keys() async throws -> [String] {
        return try self.sqlHandler.keys()
    }
    
    func keys(
        matching condition: KBGenericCondition
    ) async throws -> [String] {
        return try self.sqlHandler.keys(matching: condition)
    }
    
    func value(
        forKey key: String
    ) async throws -> Any? {
        let value = try self.sqlHandler.values(for: [key]).first
        if let v = value {
            return NSNullToNil(v)
        }
        return value
    }
    
    func values(for keys: [String]) async throws -> [Any?] {
        return try self.sqlHandler.values(for: keys).map(NSNullToNil)
    }
    
    func values(
        forKeysMatching condition: KBGenericCondition
    ) async throws -> [Any?] {
        return try self.sqlHandler.values(forKeysMatching: condition).map(NSNullToNil)
    }
    
    func keyValuesAndTimestamps(
        forKeysMatching condition: KBGenericCondition,
        timestampMatching timeCondition: KBTimestampCondition?,
        paginate: KBPaginationOptions?,
        sort: KBSortDirection?
    ) -> [KBKVPairWithTimestamp] {
        return try self.sqlHandler.keyValuesAndTimestamps(
            forKeysMatching: condition,
            timestampMatching: timeCondition,
            paginate: paginate,
            sort: sort
        )
        .map {
            KBKVPairWithTimestamp(key: $0.key, value: NSNullToNil($0.value), timestamp: $0.timestamp)
        }
    }
    
    
    func dictionaryRepresentation() async throws -> KBKVPairs {
        return try self.sqlHandler.keysAndValues()
    }
    
    func dictionaryRepresentation(
        forKeysMatching condition: KBGenericCondition
    ) async throws -> KBKVPairs {
        return try self.sqlHandler.keysAndvalues(forKeysMatching: condition)
    }
    
    func dictionaryRepresentation(
        createdWithin interval: DateInterval,
        paginate: KBPaginationOptions?,
        sort: KBSortDirection
    ) async throws -> [Date: KBKVPairs] {
        return try self.sqlHandler.keysAndValues(within: interval, paginate: paginate, sort: sort.rawValue)
    }
    
    func triplesComponents(
        matching condition: KBTripleCondition?
    ) async throws -> [KBTriple] {
        return try self.sqlHandler.tripleComponents(matching: condition)
    }
    
    func verify(path: KBPath) async throws -> Bool {
        try self.sqlHandler.verify(path: path)
    }

    //MARK: INSERT
    
    func set(value: Any?, for key: String) async throws {
        self.writeBatch().set(value: value, for: key)
        try await (self.writeBatch() as! KBSQLWriteBatch).write()
    }
    
    func setWeight(forLinkWithLabel predicate: String,
                   between subjectIdentifier: String,
                   and objectIdentifier: String,
                   toValue newValue: Int,
                   completionHandler: @escaping KBActionCompletion) {
        genericMethodReturningVoid(completionHandler) {
            try self.sqlHandler.setWeight(forLinkWithLabel: predicate,
                                          between: subjectIdentifier,
                                          and: objectIdentifier,
                                          toValue: newValue)
        }
    }
    
    func increaseWeight(forLinkWithLabel predicate: String,
                        between subjectIdentifier: String,
                        and objectIdentifier: String,
                        completionHandler: @escaping (Swift.Result<Int, Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            try self.sqlHandler.increaseWeight(forLinkWithLabel: predicate,
                                               between: subjectIdentifier,
                                               and: objectIdentifier)
        }
    }
    
    func decreaseWeight(forLinkWithLabel predicate: Label,
                        between subjectIdentifier: Label,
                        and objectIdentifier: Label,
                        completionHandler: @escaping (Swift.Result<Int, Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            try self.sqlHandler.decreaseWeight(forLinkWithLabel: predicate,
                                               between: subjectIdentifier,
                                               and: objectIdentifier)
        }
    }
    
    //MARK: DELETE
    
    func removeValue(for key: String, completionHandler: @escaping KBActionCompletion) {
        genericMethodReturningVoid(completionHandler) {
            try self.sqlHandler.removeValue(for: key)
        }
    }
    
    func removeValues(for keys: [String], completionHandler: @escaping KBActionCompletion) {
        genericMethodReturningVoid(completionHandler) {
            try self.sqlHandler.removeValues(for: keys)
        }
    }
    
    func removeValues(forKeysMatching condition: KBGenericCondition, completionHandler: @escaping (Swift.Result<[String], Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            let keys = try self.sqlHandler.keys(matching: condition)
            try self.sqlHandler.removeValues(for: keys)
            return keys
        }
    }
    
    func removeAll(completionHandler: @escaping (Swift.Result<[String], Error>) -> ()) {
        genericMethodReturningInitiable(completionHandler) {
            let keys = try self.sqlHandler.keys()
            try self.sqlHandler.removeValues(for: keys)
            return keys
        }
    }
    
    func dropLink(withLabel predicate: Label,
                  between subjectIdentifier: Label,
                  and objectIdentifier: Label,
                  completionHandler: @escaping KBActionCompletion) {
        genericMethodReturningVoid(completionHandler) {
            try self.sqlHandler.dropLink(withLabel: predicate,
                                         between: subjectIdentifier,
                                         and: objectIdentifier)
        }
    }
    
    func dropLinks(withLabel predicate: Label,
                   from subjectIdentifier: Label,
                   completionHandler: @escaping KBActionCompletion) {
        genericMethodReturningVoid(completionHandler) {
            try self.sqlHandler.dropLinks(withLabel: predicate,
                                          from: subjectIdentifier)
        }
    }
    
    func dropLinks(withLabel predicate: Label,
                   to objectIdentifier: Label,
                   completionHandler: @escaping KBActionCompletion) {
        genericMethodReturningVoid(completionHandler) {
            try self.sqlHandler.dropLinks(withLabel: predicate,
                                          to: objectIdentifier)
        }
    }
    
    func dropLinks(between subjectIdentifier: Label,
                   and objectIdentifier: Label,
                   completionHandler: @escaping KBActionCompletion) {
        genericMethodReturningVoid(completionHandler) {
            try self.sqlHandler.dropLinks(between: subjectIdentifier,
                                          and: objectIdentifier)
        }
    }
    
    func dropLinks(fromAndTo entityIdentifier: Label,
                   completionHandler: @escaping KBActionCompletion) {
        genericMethodReturningVoid(completionHandler) {
            try self.sqlHandler.dropLinks(fromAndTo: entityIdentifier)
        }
    }
    
    func disableSyncAndDeleteCloudData(completionHandler: @escaping KBActionCompletion) {
        completionHandler(.failure(KBError.notSupported))
    }
}


class KBSQLBackingStore : KBSQLBackingStoreProtocol {
    
    var name: String
    
    // SQL database on disk
    let sqlHandler: KBSQLHandler
    
    private var _baseURL: URL?

    @objc required init?(name: String, baseURL: URL? = nil) {
        self.name = name
        if let url = baseURL ?? KBSQLBackingStore.baseURL(),
           let handler = KBSQLHandler(name: self.name, baseURL: url) {
            self._baseURL = url
            self.sqlHandler = handler
        } else {
            return nil
        }
    }

    class func mainInstance() -> Self? {
        return self.init(name: KnowledgeBaseSQLDefaultIdentifier)
    }
    
    @objc static func baseURL() -> URL? {
        let directory: URL, path: URL
        
        do {
            path = try FileManager.default.url(for: .libraryDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
        } catch {
            log.fault("Could not find library directory")
            return nil
        }
        
        directory = path
        
        return directory.appendingPathComponent(KnowledgeBaseBundleIdentifier)
    }
    
    @objc var baseURL: URL? {
        if let dir = self._baseURL {
            return dir
        } else {
            self._baseURL = KBSQLBackingStore.baseURL()
            return self._baseURL
        }
    }
    
    func writeBatch() -> KBKVStoreWriteBatch {
        return KBSQLWriteBatch(backingStore: self)
    }
}

