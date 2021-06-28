import Foundation

let KnowledgeBaseBundleIdentifier = "com.gf.framework.knowledgebase"
let KnowledgeBaseInMemoryIdentifier = ":memory:"
let KnowledgeBaseUserDefaultsIdentifier = ":userDefaults:"
let KnowledgeBaseSQLDefaultIdentifier = "main"
let KnowledgeBaseSQLSynchedIdentifier = "synched"
let KnowledgeBaseSQLAggregatedEventsIdentifier = "history"


public struct KnowledgeBase {
    public private(set) var text = "Hello, World!"

    public init() {
    }
}



// MARK -- KBKnowledgeStoreDelegate

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
    internal let sparqlQueue: DispatchQueue
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
        self.sparqlQueue = DispatchQueue(label: "SPARQL",
                                                qos: .userInteractive)

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
            self.backingStore = CKCloudKitBackingStore.mainInstance()
        case .sqlSynched(let name):
            log.error("creating named sqlSynched database is not supported. %@", name)
            self.backingStore = CKCloudKitBackingStore.mainInstance()
        }
    }
}
