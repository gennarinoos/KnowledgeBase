//
//  XPCProtocol.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/27/21.
//

import Foundation

public class KnowledgeBaseXPCUtils : NSObject {
}


@objc extension KnowledgeBaseXPCUtils {
    public class func KBServiceXPCInterface() -> NSXPCInterface {
        let interface = NSXPCInterface(with: KBStorageXPCProtocol.self)

        let allowedValues = BlobValueAllowedClasses + [
            NSNull.self,
            NSString.self,
            NSNumber.self,
            NSArray.self,
            NSDictionary.self
        ]
        
        // MARK: keys(inStoreWithIdentifier:)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keys(inStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSArray.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keys(inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)

        // MARK: keys(matching:inStoreWithIdentifier:)
        interface.setClasses(NSSet(array: [KBGenericCondition.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keys(matching:inStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keys(matching:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSArray.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keys(matching:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)

        // MARK: value(forKey:inStoreWithIdentifier:)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.value(forKey:inStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.value(forKey:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)
        interface.setClasses(NSSet(array: allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.value(forKey:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)

        // MARK: keysAndValues(inStoreWithIdentifier:)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keysAndValues(inStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSDictionary.self, NSString.self] + allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keysAndValues(inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)

        // MARK: keysAndValues(forKeysMatching:inStoreWithIdentifier:)
        interface.setClasses(NSSet(array: [KBGenericCondition.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keysAndValues(forKeysMatching:inStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keysAndValues(forKeysMatching:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSDictionary.self, NSString.self] + allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keysAndValues(forKeysMatching:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)
        
        // MARK: keysAndValues(createdWithin:limit:order:inStoreWithIdentifier:)
        interface.setClasses(NSSet(array: [DateInterval.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keysAndValues(createdWithin:paginate:sort:inStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [KBPaginationOptions.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keysAndValues(createdWithin:paginate:sort:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keysAndValues(createdWithin:paginate:sort:inStoreWithIdentifier:)),
                             argumentIndex: 2,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keysAndValues(createdWithin:paginate:sort:inStoreWithIdentifier:)),
                             argumentIndex: 3,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSDate.self, NSDictionary.self, NSString.self] + allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keysAndValues(createdWithin:paginate:sort:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)

        // MARK: tripleComponents(matching:inStoreWithIdentifier:)
        interface.setClasses(NSSet(array: [KBTripleCondition.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.tripleComponents(matching:inStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.tripleComponents(matching:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSArray.self, KBTriple.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.tripleComponents(matching:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)

        // MARK: save(_:toStoreWithIdentifier:)
        interface.setClasses(NSSet(array: [NSDictionary.self, NSString.self] + allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.save(_:toStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.save(_:toStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)

        // MARK: save(_:toSynchedStoreWithIdentifier:)
        interface.setClasses(NSSet(array: [NSDictionary.self, NSString.self] + allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.save(_:toSynchedStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.save(_:toSynchedStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)

        // MARK: removeValues(forKeysMatching:fromStoreWithIdentifier:)
        interface.setClasses(NSSet(array: [KBGenericCondition.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeValues(forKeysMatching:fromStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeValues(forKeysMatching:fromStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSArray.self, NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeValues(forKeysMatching:fromStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)

        // MARK: removeValues(forKeysMatching:fromSynchedStoreWithIdentifier:
        interface.setClasses(NSSet(array: [KBGenericCondition.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeValues(forKeysMatching:fromSynchedStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeValues(forKeysMatching:fromSynchedStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSArray.self, NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeValues(forKeysMatching:fromSynchedStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)
        
        // MARK: removeAll(fromStoreWithIdentifier:)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeAll(fromStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSArray.self, NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeAll(fromStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)
        
        // MARK: removeAll(fromSynchedStoreWithIdentifier:)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeAll(fromSynchedStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSArray.self, NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeAll(fromSynchedStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)

        return interface
    }
}
