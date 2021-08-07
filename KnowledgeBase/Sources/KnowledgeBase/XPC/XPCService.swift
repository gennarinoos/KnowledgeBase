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
        
        // keys(inStoreWithIdentifier:completionHandler:)
        interface.setClasses(NSSet(array: [NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keys(inStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 1,
                             ofReply: true)

        // keys(matching:inStoreWithIdentifier:completionHandler:)
        interface.setClasses(NSSet(array: [KBGenericCondition.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keys(matching:inStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [String.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keys(matching:inStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 1,
                             ofReply: true)

        // value(forKey:inStoreWithIdentifier:completionHandler:)
        interface.setClasses(NSSet(array: allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.value(forKey:inStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 1,
                             ofReply: true)

        // keysAndValues(inStoreWithIdentifier:completionHandler:)
        interface.setClasses(NSSet(array: [NSDictionary.self, NSString.self] + allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keysAndValues(inStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 1,
                             ofReply: true)

        // keysAndValues(forKeysMatching:inStoreWithIdentifier:completionHandler:)
        interface.setClasses(NSSet(array: [KBGenericCondition.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keysAndValues(forKeysMatching:inStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSDictionary.self, NSString.self] + allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.keysAndValues(forKeysMatching:inStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 1,
                             ofReply: true)

        // tripleComponents(matching:inStoreWithIdentifier:completionHandler:)
        interface.setClasses(NSSet(array: [KBTripleCondition.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.tripleComponents(matching:inStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSArray.self, KBTriple.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.tripleComponents(matching:inStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 1,
                             ofReply: true)

        // save(_:toStoreWithIdentifier:completionHandler:)
        interface.setClasses(NSSet(array: [NSDictionary.self, NSString.self] + allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.save(_:toStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 0,
                             ofReply: false)

        // save(_:toSynchedStoreWithIdentifier:completionHandler:)
        interface.setClasses(NSSet(array: [NSDictionary.self, NSString.self] + allowedValues) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.save(_:toSynchedStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 0,
                             ofReply: false)

        // removeValues(forKeysMatching:fromStoreWithIdentifier:completionHandler:)
        interface.setClasses(NSSet(array: [KBGenericCondition.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeValues(forKeysMatching:fromStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSArray.self, NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeValues(forKeysMatching:fromStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 1,
                             ofReply: true)

        // removeValues(forKeysMatching:fromSynchedStoreWithIdentifier:completionHandler:
        interface.setClasses(NSSet(array: [KBGenericCondition.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeValues(forKeysMatching:fromSynchedStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 0,
                             ofReply: false)
        interface.setClasses(NSSet(array: [NSArray.self, NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeValues(forKeysMatching:fromSynchedStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 1,
                             ofReply: true)
        
        // MARK: .removeAll(fromStoreWithIdentifier:completionHandler:)
        interface.setClasses(NSSet(array: [NSArray.self, NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeAll(fromStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 1,
                             ofReply: true)
        
        // MARK: .removeAll(fromSynchedStoreWithIdentifier:completionHandler:)
        interface.setClasses(NSSet(array: [NSArray.self, NSString.self]) as! Set<AnyHashable>,
                             for: #selector(KBStorageXPCProtocol.removeAll(fromSynchedStoreWithIdentifier:completionHandler:)),
                             argumentIndex: 1,
                             ofReply: true)

        return interface
    }
}
