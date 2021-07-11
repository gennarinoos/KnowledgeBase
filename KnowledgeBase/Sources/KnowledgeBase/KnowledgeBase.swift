import Foundation
import RDFStorage

let KnowledgeBaseBundleIdentifier = "com.gf.framework.knowledgebase"
let KnowledgeBaseInMemoryIdentifier = ":memory:"
let KnowledgeBaseUserDefaultsIdentifier = ":userDefaults:"
let KnowledgeBaseSQLDefaultIdentifier = "main"
let KnowledgeBaseSQLSynchedIdentifier = "synched"
let KnowledgeBaseSQLAggregatedEventsIdentifier = "history"


// MARK: - KBKnowledgeStoreDelegate

@objc(KBKnowledgeStoreDelegate)
public protocol KBKnowledgeStoreDelegate {
    func linkedDataDidChange()
    /* TODO: Implement KVS Did Change Deletegate method */
}


// MARK: - KBKnowledgeStore
@objc(KBKnowledgeStore)
open class KBKnowledgeStore : NSObject {

    /// The physical location of the knowledge store.
    public enum Location : Serializable, CustomStringConvertible {

        /// An in-memory database (equivalent to `.sql(":memory:")`).
        case inMemory

        /// An UserDefaults database (equivalent to `.sql(":userDefaults:")`).
        case userDefaults

        /// A SQL database with given name.
        /// :param: name The name of the store
        case sql(String)
        
        /// An SQL database, shared across devices using CloudKit.
        /// :param: name The name of the store (local and remote names will match)
        case sqlSynched(String)
        
        public var description: String {
            return self.encoded
        }

        var encoded: String {
            switch self {
            case .inMemory: return KnowledgeBaseInMemoryIdentifier
            case .userDefaults: return KnowledgeBaseUserDefaultsIdentifier
            case .sql(let s): return "SQL::\(s)"
            case .sqlSynched(_): return KnowledgeBaseSQLSynchedIdentifier
            }
        }

        static func decode(_ encoded: String) throws -> Location {
            let components = encoded.components(separatedBy: "::")
            if components.count < 2 {
                let error = KBError.unexpectedData(encoded)
                throw error
            }
            let (prefix, name) = (components[0], components[1])
            switch prefix {
            case KnowledgeBaseSQLSynchedIdentifier: return .sqlSynched("")
            case "SQL": return .sql(name)
            case KnowledgeBaseInMemoryIdentifier: return .inMemory
            case KnowledgeBaseUserDefaultsIdentifier: return .userDefaults
            default: return .inMemory
            }
        }
    }

    internal let backingStore: KBBackingStore
    public let location: Location

    @objc open var delegate: KBKnowledgeStoreDelegate?

    @objc open var name: String {
        return self.backingStore.name
    }
 
    @objc(directoryURL)
    public static func directory() -> URL? {
        return KBSQLBackingStore.directory
    }
    
    @objc(filePathURL)
    open var filePath: URL? {
        if self.backingStore is KBSQLBackingStore {
            return KBKnowledgeStore.directory()?
                .appendingPathComponent(self.name)
                .appendingPathExtension(DatabaseExtension)
        }
        return nil
    }
    
    // MARK: NSObjectProtocol, Hashable, Equatable

    @objc open override var hash: Int {
        return self.name.hashValue
    }
    @objc open override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? KBKnowledgeStore {
            return self.name == object.name
        }
        return false
    }

    // MARK: Constructors / Destructors

    @objc open class func defaultKnowledgeStore() -> KBKnowledgeStore {
        return KBKnowledgeStore.knowledgeStore(withName: "")
    }
    
    @objc open class func defaultSynchedKnowledgeStore() -> KBKnowledgeStore {
        return KBKnowledgeStore.synchedKnowledgeStore(withName: "")
    }

    @objc open class func inMemoryKnowledgeStore() -> KBKnowledgeStore {
        return KBKnowledgeStore.store(Location.inMemory)
    }

    @objc open class func userDefaultsKnowledgeStore() -> KBKnowledgeStore {
        return KBKnowledgeStore.store(Location.userDefaults)
    }
    
    @objc open class func knowledgeStore(withName name: String) -> KBKnowledgeStore {
        if name == KnowledgeBaseInMemoryIdentifier {
            return KBKnowledgeStore.store(.inMemory)
        } else if name == KnowledgeBaseUserDefaultsIdentifier {
            return KBKnowledgeStore.store(.userDefaults)
        }
        return KBKnowledgeStore.store(Location.sql(name))
    }
    
    @objc open class func synchedKnowledgeStore(withName name: String) -> KBKnowledgeStore {
        return KBKnowledgeStore(Location.sqlSynched(name))
    }

    open class func store(_ location: Location) -> KBKnowledgeStore {
        return KBKnowledgeStore(location)
    }

    fileprivate init(_ location: Location) {
        self.location = location

        switch (self.location) {
        case .inMemory, .sql(KnowledgeBaseInMemoryIdentifier):
            self.backingStore = KBInMemoryBackingStore()
        case .userDefaults, .sql(KnowledgeBaseUserDefaultsIdentifier):
            self.backingStore = KBUserDefaultsBackingStore()
        case .sql(""):
            self.backingStore = KBSQLBackingStore.mainInstance()
        case .sql(let name):
            self.backingStore = KBSQLBackingStore(name: name)
        case .sqlSynched(""):
#if os(macOS)
            self.backingStore = KBCloudKitSQLXPCBackingStore.mainInstance()
#else
            self.backingStore = KBCloudKitSQLBackingStore.mainInstance()
#endif
        case .sqlSynched(let name):
            log.error("creating named sqlSynched database is not supported. %@", name)
#if os(macOS)
            self.backingStore = KBCloudKitSQLXPCBackingStore.mainInstance()
#else
            self.backingStore = KBCloudKitSQLBackingStore.mainInstance()
#endif
        }
    }
}

// MARK: KBReadableKnowledgeBase
extension KBKnowledgeStore {
    
    //MARK: dictionaryRepresentation()
    
    /**
     Retrieves all keys and values in the KVS.
     
     - returns the dictionary containing all keys and values
     
     */
    @objc open func dictionaryRepresentation() async throws -> KBJSONObject {
        return try await self.backingStore.dictionaryRepresentation()
    }
    
    /**
     Retrieves all keys and values in the KVS, where the keys match the condition.
     
     - parameter condition: the condition to match keys against
     - returns the dictionary containing all keys and values matching the condition
     
     */
    @objc open func dictionaryRepresentation(forKeysMatching condition: KBGenericCondition) async throws -> KBJSONObject {
        return try await self.backingStore.dictionaryRepresentation(forKeysMatching: condition)
    }
    
    
    //MARK: keys()
    
    /**
     Retrieves all the keys in the KVS.
     
     - parameter completionHandler: the callback method
     - returns the keys
     
     */
    @objc open func keys() async throws -> [String] {
        return try await self.backingStore.keys()
    }
    
    /**
     Retrieves all the keys in the KVS matching the condition.
     
     - parameter condition: condition the keys need to satisfy
     - returns the keys
     
     */
    @objc open func keys(matching condition: KBGenericCondition) async throws -> [String] {
        return try await self.backingStore.keys(matching: condition)
    }
    
    //MARK: values()
    
    /**
     Retrieves all the values in the KVS.
     
     - parameter completionHandler: the callback method
     - returns the values
     
     */
    @objc open func values() async throws -> [Any] {
        return try await self.backingStore.values()
    }
    
    //MARK: value(forKey:)
    
    /**
     Retrieves the value corresponding to the key in the KVS.
     
     - parameter key: the key
     - returns the value for the key. nil if the key doesn't exist, NSNull if set to null
     
     */
    @objc open func value(forKey key: String) async throws -> Any? {
        return try await self.backingStore._value(forKey: key)
    }
    
    
    //MARK: values(forKeys:)
    
    /**
     Retrieves the value corresponding to the keys passed as input from the KVS.
     Appends nil for values not present in the KVS for the corresponding key.
     
     - parameter keys: the set of keys
     - returns the list of values for the keys
     
     */
    @objc open func values(forKeys keys: [String]) async throws -> [Any] {
        var values = [Any]()
        for nullableValue in try await self.backingStore.values(forKeys: keys) {
            if nullableValue == nil {
                values.append(NSNull())
            } else {
                values.append(nullableValue!)
            }
        }
        return values
    }
    
    /**
     Retrieves the values in the KVS whose keys pass the condition.
     
     - parameter condition: condition the keys need to satisfy
     - returns the list of values for the keys matching the condition
     
     */
    @objc open func values(forKeysMatching condition: KBGenericCondition) async throws -> [Any] {
        return try await self.backingStore.values(forKeysMatching: condition)
    }
    
    //MARK: entity(withIdentifier:)
    
    /**
     Construct a KBEntity object
     
     - parameter identifier: the unique identifier of the entity
     - returns: A KBEntity object
     
     */
    @objc open func entity(withIdentifier identifier: Label) -> KBEntity {
        return KBEntity(identifier: identifier, knowledgeStore: self)
    }
    
    // MARK: - SELECT GRAPH
    
    //MARK: entities()
    
    /**
     All entities
     
     - returns: A list of KBEntity objects
     
     */
    @objc open func entities() async throws -> [KBEntity] {
        var uniqueIDs = Set<Label>()
        
        let results = try await self.backingStore.values()
            
        for value in results {
            if let triple = value as? KBTriple {
                uniqueIDs.insert(triple.subject)
                uniqueIDs.insert(triple.object)
            }
        }
            
        return uniqueIDs.map {
            self.entity(withIdentifier: $0)
        }
    }
    
    //MARK: triples(matching:)
    
    /**
     Matches triples need against the condition passed as argument
     
     - parameter condition: matches only triples having satisfying this condition.
     If nil, matches all triples
     
     - returns: The array of triples in a dictionary with keys: subject, predicate, object
     */
    @objc open func triples(matching condition: KBTripleCondition?) async throws -> [KBTriple] {
        return try await self.backingStore.triplesComponents(matching: condition)
    }

}

extension KBKnowledgeStore {
    
    // MARK: - WRITE BATCH
    
    @objc open func writeBatch() -> KBKnowledgeStoreWriteBatch {
        return self.backingStore.writeBatch()
    }
    
    // MARK: - INSERT KVS
    
    //MARK: setValue(forKey:)
    
    /**
     Assign a value, or nil, to a specific key in the KVS.
     
     - parameter value: the value
     - parameter key: the key
     
     */
    @objc open func setValue(_ value: Any?, forKey key: String) async throws {
        guard self.supportsSecureCoding(value) else {
            log.error("Trying to save a non NSSecureCoding compliant value `%@` for key %@", String(describing: value), key);
            throw KBError.unexpectedData(value)
        }
        
        let writeBatch = self.writeBatch()
        writeBatch.setObject(value, forKey: key)
        try await writeBatch.write()
    }
    
    /**
     Check if value supports secure coding (is conform to NSSecureCoding).
     The value nil is considered conformed.
     
     - parameter value: value to check
     */
    private func supportsSecureCoding(_ value: Any?) -> Bool {
        if let v = value {
            return ((v as? NSSecureCoding) != nil)
        }
        
        return true
    }
    
    //MARK: - DELETE GRAPH
    
    //MARK: removeEntity()
    
    /**
     Remove the entity with a certain identifier.
     WARN: This will remove all the connections to this entity in the graph.
     
     - parameter identifier: the identifier
     */
    @objc open func removeEntity(_ identifier: Label) async throws {
        log.debug("[$? <%{private}@> $?]", identifier)
        
        let subjectMatches = KBTripleCondition(
            subject: identifier,
            predicate: nil,
            object: nil
        )
        let objectMatches = KBTripleCondition(
            subject: nil,
            predicate: nil,
            object: identifier
        )
        let condition = subjectMatches.or(objectMatches)
        
        try await self.backingStore.removeValues(matching: condition.rawCondition)
    }
    
    
    //MARK: removeValue(forKey:)
    
    /**
     Remove a tuple in the KVS, given its key.
     
     - parameter key: the key
     
     */
    @objc open func removeValue(forKey key: String) async throws {
        try await self.backingStore.removeValue(forKey: key)
    }
    
    //MARK: removeValues(forKeys:)
    
    /**
     Remove a set of tuples in the KVS, given their keys.
     Blocking version
     
     - parameter keys: the keys
     
     */
    @objc open func removeValues(forKeys keys: [String]) async throws {
        try await self.backingStore.removeValues(forKeys: keys)
    }
    
    //MARK: removeValues(matching:)
    
    /**
     Remove a set of tuples in the KVS, matching the condition.
     
     - parameter condition: the condition
     */
    @objc open func removeValues(matching condition: KBGenericCondition) async throws {
        try await self.backingStore.removeValues(matching: condition)
    }
    
    //MARK: removeAllValues()
    
    /**
     Remove all values in the KVS
     */
    @objc open func removeAllValues() async throws {
        try await self.backingStore.removeAllValues()
        self.delegate?.linkedDataDidChange()
    }
    
    /**
     Disable CloudKit syncing and remove all the data in the cloud
     */
    @objc open func disableSyncAndDeleteCloudData() async throws {
        try await self.backingStore.disableSyncAndDeleteCloudData()
    }
    
}


extension KBKnowledgeStore : TripleStore {
    
    public func insertTriple(withSubject subject: String, predicate: String, object: String) async throws {
        let subject = self.entity(withIdentifier: subject)
        let object = self.entity(withIdentifier: object)
        
        try await subject.link(to: object, withPredicate: predicate)
    }
    
    
    @objc open func importContentsOfTurtle(fromFileAt path: String) async throws {
        let solver = KBSPARQLEndpoint(with: self)
        try await solver.importTurtle(fromFileAt: path)
    }
    
    /**
     Executes the SPARQL SELECT query and returns all the bounded values in the projection.
     
     - parameter query: the SPARQL SELECT query to execute
     */
    @objc open func execute(SPARQLQuery query: String) async throws -> [Any] {
        let solver = KBSPARQLEndpoint(with: self)
        return try await solver.execute(query: query)
    }

    
    // MARK: TripleStore protocol
    
    public func insertTriple(withSubject subject: String, predicate: String, object: String, error: NSErrorPointer) {
        
    }
}

