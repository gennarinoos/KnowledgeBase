//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/27/21.
//

import Foundation

public class KnowledgeBaseXPCUtils : NSObject {
}


@objc extension KnowledgeBaseXPCUtils {
    public class func KBServiceXPCInterface() -> NSXPCInterface {
        let interface = NSXPCInterface(with: KBStorageXPCInterface.self)

        let allowedValues = BlobValueAllowedClasses + [
            NSNull.self,
            NSString.self,
            NSNumber.self,
            NSArray.self,
            NSDictionary.self
        ]

        // keysMatching:inStoreWithIdentifier:completionHandler:
        interface.setClasses(NSSet(array: [KBGenericCondition.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.keys(matching:inStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.keys(matching:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSArray.self, NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.keys(matching:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)

        // valueForKey:inStoreWithIdentifier:completionHandler:
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.value(forKey:inStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.value(forKey:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)
        interface.setClasses(NSSet(array: allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.value(forKey:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)

        // keysAndValuesInStoreWithIdentifier:completionHandler:
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.keysAndValues(inStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSDictionary.self, NSString.self] + allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.keysAndValues(inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)

        // keysAndValuesForKeysMatching:inStoreWithIdentifier:completionHandler:
        interface.setClasses(NSSet(array: [KBGenericCondition.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.keysAndValues(forKeysMatching:inStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.keysAndValues(forKeysMatching:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSDictionary.self, NSString.self] + allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.keysAndValues(forKeysMatching:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)

        // tripleComponentsMatching:inStoreWithIdentifier:completionHandler:
        interface.setClasses(NSSet(array: [KBTripleCondition.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.tripleComponents(matching:inStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.tripleComponents(matching:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSArray.self, KBTriple.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.tripleComponents(matching:inStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: true)

        // save:toStoreWithIdentifier:completionHandler:
        interface.setClasses(NSSet(array: [NSDictionary.self, NSString.self] + allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.save(_:toStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.save(_:toStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)

        // save:toSynchedStoreWithIdentifier:completionHandler:
        interface.setClasses(NSSet(array: [NSDictionary.self, NSString.self] + allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.save(_:toSynchedStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.save(_:toSynchedStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)

        // removeValuesMatching:fromStoreWithIdentifier:completionHandler:
        interface.setClasses(NSSet(array: [KBGenericCondition.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.removeValues(matching:fromStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.removeValues(matching:fromStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)

        // removeValuesMatching:fromSynchedStoreWithIdentifier:completionHandler:
        interface.setClasses(NSSet(array: [KBGenericCondition.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.removeValues(matching:fromSynchedStoreWithIdentifier:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCInterface.removeValues(matching:fromSynchedStoreWithIdentifier:)),
                             argumentIndex: 1,
                             ofReply: false)

        return interface
    }
}
