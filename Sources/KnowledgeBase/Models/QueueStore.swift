//
//  QueueStore.swift
//  
//
//  Created by Gennaro Frazzingaro on 9/4/21.
//

import Foundation

@objc(KBQueueStore)
public class KBQueueStore : KBKVStore {
    
    public enum QueueType {
        /// First in - first out
        case fifo
        /// Last in - first out
        case lifo
    }

    public let queueType: QueueType
    
    @available(*, unavailable)
    override init?(_ location: Location) {
        log.critical("\(#function) is not supported for objects of type KBQueueStore")
        return nil
    }
    
    @available(*, unavailable)
    @objc public override class func defaultStore() -> KBQueueStore? {
        log.critical("\(#function) is not supported for objects of type KBQueueStore")
        return nil
    }
    
    @available(*, unavailable)
    @objc public override class func defaultSynchedStore() -> KBQueueStore? {
        log.critical("\(#function) is not supported for objects of type KBQueueStore")
        return nil
    }

    @available(*, unavailable)
    @objc public override class func inMemoryStore() -> KBQueueStore? {
        log.critical("\(#function) is not supported for objects of type KBQueueStore")
        return nil
    }

    @available(*, unavailable)
    @objc public override class func userDefaultsStore() -> KBQueueStore? {
        log.critical("\(#function) is not supported for objects of type KBQueueStore")
        return nil
    }
    
    @available(*, unavailable)
    public override class func store(withName name: String) -> KBQueueStore? {
        log.critical("\(#function) is not supported for objects of type KBQueueStore")
        return nil
    }
    
    @available(*, unavailable)
    public override class func store(_ location: Location) -> KBQueueStore? {
        log.critical("\(#function) is not supported for objects of type KBQueueStore")
        return nil
    }
    
    @available(*, unavailable)
    @objc public override class func synchedStore(withName name: String) -> KBQueueStore? {
        log.critical("\(#function) is not supported for objects of type KBQueueStore")
        return nil
    }
    
    init?(_ location: Location, type: QueueType) {
        self.queueType = type
        super.init(location)
    }
    
    public class func defaultStore(type: QueueType) -> KBQueueStore? {
        return KBQueueStore.store(withName: "", type: type)
    }
    
    @available(*, unavailable)
    public class func defaultSynchedStore(type: QueueType) -> KBQueueStore? {
        log.critical("A synched store can't be used as a backing storage for a KBQueueStore")
        return nil
    }

    public class func inMemoryStore(type: QueueType) -> KBQueueStore? {
        return KBQueueStore.store(Location.inMemory, type: type)
    }

    @available(*, unavailable)
    public class func userDefaultsStore(type: QueueType) -> KBQueueStore? {
        log.critical("A synched store can't be used as a backing storage for a KBQueueStore")
        return nil
    }
    
    public class func store(withName name: String, type: QueueType) -> KBQueueStore? {
        if name == KnowledgeBaseInMemoryIdentifier {
            return KBQueueStore.store(.inMemory, type: type)
        } else if name == KnowledgeBaseUserDefaultsIdentifier {
            fatalError("UserDefaults can't be used as a backing storage for a KBQueueStore")
        }
        return KBQueueStore.store(Location.sql(name), type: type)
    }
    
    public class func store(_ location: Location, type: QueueType) -> KBQueueStore? {
        switch location {
        case .inMemory, .sql(_):
            return KBQueueStore(location, type: type)
        default:
            return KBQueueStore(location, type: type)
        }
    }

    @available(*, unavailable)
    public class func synchedStore(withName name: String, type: QueueType) -> KBQueueStore? {
        log.critical("A synched store can't be used as a backing storage for a KBQueueStore")
        return nil
    }
}
